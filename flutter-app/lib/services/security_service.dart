import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' hide Key;
import 'package:encrypt/encrypt.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SecurityService — Handles authentication security, rate limiting,
// offline credential validation, and local data encryption.
//
// SECURITY UPGRADE:
//   • Encryption: AES-256-GCM (replaces old XOR cipher)
//   • Password hashing: bcrypt with 12 rounds (replaces plain SHA-256)
//   • Key generation: cryptographically secure random (replaces timestamp-based)
//   • Integrity: GCM authentication tag (replaces SHA-256 HMAC)
// ═══════════════════════════════════════════════════════════════════════════════

class SecurityService {
  // ── SharedPreferences keys ───────────────────────────────────────────────
  static const _keyStoredEmail = 'sec_stored_email';
  static const _keyStoredPasswordHash = 'sec_stored_pwd_hash';
  static const _keyFailedAttempts = 'sec_failed_attempts';
  static const _keyFirstFailTime = 'sec_first_fail_time';
  static const _keyLockUntil = 'sec_lock_until';
  static const _keyHasOnlineSession = 'sec_has_online_session';
  static const _keyEncryptionKey = 'sec_enc_key';
  // Legacy key — no longer used with bcrypt, cleared on migration
  static const _keySalt = 'sec_salt';
  // Migration flag — ensures old credentials are invalidated on first run
  static const _keySecurityMigrated = 'sec_migrated_v2';

  // ── Rate limit configuration ─────────────────────────────────────────────
  static const int maxAttempts = 5;
  static const Duration lockDuration = Duration(minutes: 5);
  // Progressive lockout: each round doubles the lock time
  static const int maxLockoutRounds = 4; // 5min → 10min → 20min → 40min

  // ── Encryption state ─────────────────────────────────────────────────────
  static final _secureRandom = Random.secure();
  static String? _cachedEncryptionKey;
  static Encrypter? _cachedEncrypter;

  SecurityService._();

  // ═══════════════════════════════════════════════════════════════════════════
  //  INITIALIZATION & MIGRATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Run once on app startup to migrate from old (insecure) security format.
  /// Invalidates old SHA-256 hashed credentials — user must re-login online.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final migrated = prefs.getBool(_keySecurityMigrated) ?? false;

    if (!migrated) {
      debugPrint('Security: Migrating to v2 (AES-256-GCM + bcrypt)');

      // Clear old insecure credentials (SHA-256 hashes are no longer valid)
      await prefs.remove(_keyStoredEmail);
      await prefs.remove(_keyStoredPasswordHash);
      await prefs.remove(_keySalt);

      // Regenerate encryption key (old key was timestamp-based, weak)
      await prefs.remove(_keyEncryptionKey);
      _cachedEncryptionKey = null;
      _cachedEncrypter = null;

      // Mark migration complete
      await prefs.setBool(_keySecurityMigrated, true);
      await prefs.setBool(_keyHasOnlineSession, false);

      debugPrint('Security: Migration complete — old credentials cleared');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  OFFLINE CREDENTIAL VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether the user has ever logged in online successfully.
  static Future<bool> hasOnlineSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasOnlineSession) ?? false;
  }

  /// Store credentials hash after successful online login for offline use.
  /// Uses bcrypt with 12 rounds — industry standard for password hashing.
  static Future<void> storeOfflineCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    // bcrypt: generates salt internally and embeds it in the hash ($2a$12$...)
    final hash = BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 12));

    await prefs.setString(_keyStoredEmail, email.toLowerCase().trim());
    await prefs.setString(_keyStoredPasswordHash, hash);
    await prefs.setBool(_keyHasOnlineSession, true);

    debugPrint('Security: Offline credentials stored (bcrypt 12 rounds)');
  }

  /// Validate credentials against stored bcrypt hash for offline login.
  /// Returns true if credentials match.
  static Future<bool> validateOfflineCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    final storedEmail = prefs.getString(_keyStoredEmail) ?? '';
    final storedHash = prefs.getString(_keyStoredPasswordHash) ?? '';

    if (storedEmail.isEmpty || storedHash.isEmpty) {
      return false;
    }

    // bcrypt: salt is embedded in the hash, no separate salt needed
    final emailMatch = email.toLowerCase().trim() == storedEmail;
    final passwordMatch = BCrypt.checkpw(password, storedHash);

    return emailMatch && passwordMatch;
  }

  /// Clear stored offline credentials (called on sign-out).
  static Future<void> clearOfflineCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStoredEmail);
    await prefs.remove(_keyStoredPasswordHash);
    await prefs.remove(_keySalt); // cleanup legacy salt
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
  //  DATA ENCRYPTION — AES-256-GCM
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a cryptographically secure 32-byte key (AES-256).
  static String _generateSecureKey() {
    final bytes = List<int>.generate(32, (_) => _secureRandom.nextInt(256));
    return base64Encode(bytes);
  }

  /// Generate a cryptographically secure 12-byte nonce (GCM standard).
  static Uint8List _generateNonce() {
    return Uint8List.fromList(
      List<int>.generate(12, (_) => _secureRandom.nextInt(256)),
    );
  }

  /// Get or create the AES-256-GCM encrypter instance.
  static Future<Encrypter> _getEncrypter() async {
    if (_cachedEncrypter != null) return _cachedEncrypter!;

    final prefs = await SharedPreferences.getInstance();
    var keyBase64 = prefs.getString(_keyEncryptionKey);

    if (keyBase64 == null || keyBase64.isEmpty) {
      keyBase64 = _generateSecureKey();
      await prefs.setString(_keyEncryptionKey, keyBase64);
      debugPrint('Security: New AES-256 key generated');
    }

    _cachedEncryptionKey = keyBase64;
    final key = Key.fromBase64(keyBase64);
    _cachedEncrypter = Encrypter(AES(key, mode: AESMode.gcm));

    return _cachedEncrypter!;
  }

  /// Get the encryption key (for diagnostics only).
  static Future<String> getEncryptionKey() async {
    if (_cachedEncryptionKey != null) return _cachedEncryptionKey!;

    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyEncryptionKey);
    if (key != null) _cachedEncryptionKey = key;
    return key ?? '';
  }

  /// Encrypt a string using AES-256-GCM.
  ///
  /// Output format: `nonce_base64.ciphertext_base64`
  /// The GCM mode provides both confidentiality AND integrity (authentication tag).
  static Future<String> encryptValue(String plainText) async {
    if (plainText.isEmpty) return '';

    try {
      final encrypter = await _getEncrypter();
      final nonce = _generateNonce();
      final iv = IV(nonce);

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Format: nonce.base64 + '.' + ciphertext.base64
      return '${base64Encode(nonce)}.${encrypted.base64}';
    } catch (e) {
      debugPrint('Security: AES-256-GCM encryption error: $e');
      return '';
    }
  }

  /// Decrypt a string using AES-256-GCM.
  ///
  /// Expected format: `nonce_base64.ciphertext_base64`
  /// If decryption or integrity check fails, returns empty string.
  static Future<String> decryptValue(String encryptedText) async {
    if (encryptedText.isEmpty) return '';

    try {
      final parts = encryptedText.split('.');
      if (parts.length != 2) return '';

      final nonce = base64Decode(parts[0]);
      final iv = IV(nonce);
      final encrypted = Encrypted.fromBase64(parts[1]);

      final encrypter = await _getEncrypter();
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      debugPrint('Security: AES-256-GCM decryption error: $e');
      return '';
    }
  }

  /// Encrypt a map (JSON) to a string using AES-256-GCM.
  static Future<String> encryptMap(Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    return encryptValue(jsonStr);
  }

  /// Decrypt a string back to a map (JSON) using AES-256-GCM.
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
  //  SECURITY AUDIT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get current security status for diagnostics.
  static Future<Map<String, dynamic>> getSecurityStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSession = prefs.getBool(_keyHasOnlineSession) ?? false;
    final hasCredentials = (prefs.getString(_keyStoredEmail) ?? '').isNotEmpty;
    final failedAttempts = prefs.getInt(_keyFailedAttempts) ?? 0;
    final lockout = await getRemainingLockout();
    final migrated = prefs.getBool(_keySecurityMigrated) ?? false;
    final storedHash = prefs.getString(_keyStoredPasswordHash) ?? '';
    final usesBcrypt = storedHash.startsWith(r'$2');

    return {
      'securityVersion': 'v2',
      'encryption': 'AES-256-GCM',
      'passwordHashing': usesBcrypt ? 'bcrypt' : 'legacy',
      'migrated': migrated,
      'hasOnlineSession': hasSession,
      'hasStoredCredentials': hasCredentials,
      'failedAttempts': failedAttempts,
      'isLocked': lockout > Duration.zero,
      'lockoutRemaining': lockout.inSeconds,
    };
  }
}
