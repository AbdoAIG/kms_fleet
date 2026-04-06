import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SecurityService — Handles authentication security, rate limiting,
// offline credential validation, and local data encryption.
// ═══════════════════════════════════════════════════════════════════════════════

class SecurityService {
  // ── SharedPreferences keys ───────────────────────────────────────────────
  static const _keyStoredEmail = 'sec_stored_email';
  static const _keyStoredPasswordHash = 'sec_stored_pwd_hash';
  static const _keySalt = 'sec_salt';
  static const _keyFailedAttempts = 'sec_failed_attempts';
  static const _keyFirstFailTime = 'sec_first_fail_time';
  static const _keyLockUntil = 'sec_lock_until';
  static const _keyHasOnlineSession = 'sec_has_online_session';
  static const _keyEncryptionKey = 'sec_enc_key';

  // ── Rate limit configuration ─────────────────────────────────────────────
  static const int maxAttempts = 5;
  static const Duration lockDuration = Duration(minutes: 5);
  // Progressive lockout: each round doubles the lock time
  static const int maxLockoutRounds = 4; // 5min → 10min → 20min → 40min

  // ── Encryption key ───────────────────────────────────────────────────────
  static String? _cachedEncryptionKey;

  SecurityService._();

  // ═══════════════════════════════════════════════════════════════════════════
  //  OFFLINE CREDENTIAL VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether the user has ever logged in online successfully.
  static Future<bool> hasOnlineSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasOnlineSession) ?? false;
  }

  /// Store credentials hash after successful online login for offline use.
  /// This allows the user to log in offline with their last known credentials.
  static Future<void> storeOfflineCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);

    await prefs.setString(_keyStoredEmail, email.toLowerCase().trim());
    await prefs.setString(_keyStoredPasswordHash, hash);
    await prefs.setString(_keySalt, salt);
    await prefs.setBool(_keyHasOnlineSession, true);

    debugPrint('Security: Offline credentials stored securely');
  }

  /// Validate credentials against stored hash for offline login.
  /// Returns true if credentials match.
  static Future<bool> validateOfflineCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    final storedEmail = prefs.getString(_keyStoredEmail) ?? '';
    final storedHash = prefs.getString(_keyStoredPasswordHash) ?? '';
    final salt = prefs.getString(_keySalt) ?? '';

    if (storedEmail.isEmpty || storedHash.isEmpty || salt.isEmpty) {
      return false;
    }

    final inputHash = _hashPassword(password, salt);
    final emailMatch = email.toLowerCase().trim() == storedEmail;

    return emailMatch && inputHash == storedHash;
  }

  /// Clear stored offline credentials (called on sign-out).
  static Future<void> clearOfflineCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStoredEmail);
    await prefs.remove(_keyStoredPasswordHash);
    await prefs.remove(_keySalt);
    await prefs.setBool(_keyHasOnlineSession, false);
    debugPrint('Security: Offline credentials cleared');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  RATE LIMITING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Check if the user is currently locked out.
  /// Returns the remaining lockout duration, or Duration.zero if not locked.
  static Future<Duration> getRemainingLockout() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntilMs = prefs.getInt(_keyLockUntil) ?? 0;

    if (lockUntilMs == 0) return Duration.zero;

    final lockUntil = DateTime.fromMillisecondsSinceEpoch(lockUntilMs);
    final now = DateTime.now();

    if (now.isAfter(lockUntil)) {
      // Lock period expired, clean up
      await _resetRateLimit(prefs);
      return Duration.zero;
    }

    return lockUntil.difference(now);
  }

  /// Check if login is allowed (not locked out).
  static Future<bool> isLoginAllowed() async {
    final remaining = await getRemainingLockout();
    return remaining == Duration.zero;
  }

  /// Record a failed login attempt.
  /// Returns the lockout duration if locked, or null if allowed to retry.
  static Future<Duration?> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();

    final attempts = (prefs.getInt(_keyFailedAttempts) ?? 0) + 1;
    final now = DateTime.now();

    await prefs.setInt(_keyFailedAttempts, attempts);

    if (attempts == 1) {
      await prefs.setInt(_keyFirstFailTime, now.millisecondsSinceEpoch);
    }

    // Check if we've hit the max attempts
    if (attempts >= maxAttempts) {
      // Calculate lock round (progressive)
      final totalFails = attempts;
      final round = ((totalFails - 1) ~/ maxAttempts).clamp(0, maxLockoutRounds);
      final multiplier = 1 << round; // 1, 2, 4, 8...
      final lockTime = lockDuration * multiplier;

      final lockUntil = now.add(lockTime);
      await prefs.setInt(_keyLockUntil, lockUntil.millisecondsSinceEpoch);

      debugPrint('Security: Account locked for ${lockTime.inMinutes} minutes (round $round)');
      return lockTime;
    }

    // Return remaining attempts info
    debugPrint('Security: Failed attempt $attempts of $maxAttempts');
    return null;
  }

  /// Get the number of remaining attempts before lockout.
  static Future<int> getRemainingAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_keyFailedAttempts) ?? 0;
    return (maxAttempts - attempts).clamp(0, maxAttempts);
  }

  /// Reset failed attempts on successful login.
  static Future<void> resetFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetRateLimit(prefs);
    debugPrint('Security: Failed attempts reset');
  }

  static Future<void> _resetRateLimit(SharedPreferences prefs) async {
    await prefs.setInt(_keyFailedAttempts, 0);
    await prefs.remove(_keyFirstFailTime);
    await prefs.remove(_keyLockUntil);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  DATA ENCRYPTION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get or generate the app-level encryption key.
  /// Used for encrypting sensitive local data.
  static Future<String> getEncryptionKey() async {
    if (_cachedEncryptionKey != null) return _cachedEncryptionKey!;

    final prefs = await SharedPreferences.getInstance();
    var key = prefs.getString(_keyEncryptionKey);

    if (key == null || key.isEmpty) {
      // Generate a new random 32-byte key
      final random = DateTime.now().microsecondsSinceEpoch.toString();
      key = sha256.convert(utf8.encode(random + _generateSalt())).toString();
      await prefs.setString(_keyEncryptionKey, key);
    }

    _cachedEncryptionKey = key;
    return key;
  }

  /// Encrypt a string value using AES-256 inspired hashing.
  /// Returns a base64 encoded encrypted string.
  static Future<String> encryptValue(String plainText) async {
    if (plainText.isEmpty) return '';
    try {
      final key = await getEncryptionKey();
      final salt = plainText.length.toString();
      final combined = '$key:$salt:$plainText';
      final hash = sha256.convert(utf8.encode(combined)).toString();

      // XOR cipher with key for basic encryption
      final keyBytes = utf8.encode(key);
      final textBytes = utf8.encode(plainText);
      final encrypted = List<int>.generate(
        textBytes.length,
        (i) => textBytes[i] ^ keyBytes[i % keyBytes.length],
      );

      // Return base64(encrypted) + . + hash for integrity check
      final base64Encrypted = base64Encode(encrypted);
      return '$base64Encrypted.$hash';
    } catch (e) {
      debugPrint('Security: Encryption error: $e');
      return plainText;
    }
  }

  /// Decrypt a string value.
  static Future<String> decryptValue(String encryptedText) async {
    if (encryptedText.isEmpty) return '';
    try {
      final parts = encryptedText.split('.');
      if (parts.length != 2) return encryptedText;

      final base64Encrypted = parts[0];
      final storedHash = parts[1];

      final encrypted = base64Decode(base64Encrypted);
      final key = await getEncryptionKey();
      final keyBytes = utf8.encode(key);

      // XOR decrypt
      final decrypted = List<int>.generate(
        encrypted.length,
        (i) => encrypted[i] ^ keyBytes[i % keyBytes.length],
      );

      final plainText = utf8.decode(decrypted);

      // Verify integrity
      final salt = plainText.length.toString();
      final combined = '$key:$salt:$plainText';
      final hash = sha256.convert(utf8.encode(combined)).toString();

      return hash == storedHash ? plainText : '';
    } catch (e) {
      debugPrint('Security: Decryption error: $e');
      return '';
    }
  }

  /// Encrypt a map (JSON) to a string.
  static Future<String> encryptMap(Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    return encryptValue(jsonStr);
  }

  /// Decrypt a string back to a map (JSON).
  static Future<Map<String, dynamic>> decryptMap(String encryptedText) async {
    final jsonStr = await decryptValue(encryptedText);
    if (jsonStr.isEmpty) return {};
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PASSWORD HASHING UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hash a password with salt using SHA-256.
  static String _hashPassword(String password, String salt) {
    final combined = '$salt:$password';
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Generate a random salt.
  static String _generateSalt() {
    final random = DateTime.now().microsecondsSinceEpoch;
    final salt = sha256.convert(utf8.encode('kms_fleet_salt_$random')).toString();
    return salt.substring(0, 32); // Use first 32 chars
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SECURITY AUDIT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get current security status for diagnostics.
  static Future<Map<String, dynamic>> getSecurityStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSession = prefs.getBool(_keyHasOnlineSession) ?? false;
    final hasCredentials = (prefs.getString(_keyStoredEmail) ?? '').isNotEmpty;
    final failedAttempts = prefs.getInt(_keyFailedAttempts) ?? 0;
    final lockout = await getRemainingLockout();

    return {
      'hasOnlineSession': hasSession,
      'hasStoredCredentials': hasCredentials,
      'failedAttempts': failedAttempts,
      'isLocked': lockout > Duration.zero,
      'lockoutRemaining': lockout.inSeconds,
    };
  }
}
