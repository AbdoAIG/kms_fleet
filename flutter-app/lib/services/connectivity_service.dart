// ─────────────────────────────────────────────────────────────────────────────
// connectivity_service.dart
// ─────────────────────────────────────────────────────────────────────────────
//
// Monitors network connectivity and triggers automatic sync when the
// connection is restored. Works alongside SupabaseSyncService to ensure
// data consistency across all devices.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'supabase_service.dart';
import 'supabase_sync_service.dart';

class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static bool _isInitialized = false;
  static DateTime? _lastSyncTime;
  static Timer? _periodicSyncTimer;

  /// Minimum interval between auto-syncs (30 seconds).
  static const Duration _syncCooldown = Duration(seconds: 30);

  /// Periodic sync interval (3 minutes).
  static const Duration _periodicInterval = Duration(minutes: 3);

  // ── Public state ──────────────────────────────────────────────────────────

  static bool isOnline = true;

  // ── Initialization ────────────────────────────────────────────────────────

  /// Start monitoring connectivity. Should be called after login.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Check current connectivity state
    try {
      final results = await _connectivity.checkConnectivity();
      _updateOnlineState(results);
    } catch (e) {
      debugPrint('Connectivity: Error checking initial state: $e');
      isOnline = false;
    }

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Start periodic sync timer
    _startPeriodicSync();

    debugPrint('Connectivity: Service initialized (online=$isOnline)');
  }

  /// Stop monitoring connectivity. Should be called on logout.
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    _isInitialized = false;
    debugPrint('Connectivity: Service disposed');
  }

  // ── Connectivity change handler ───────────────────────────────────────────

  static void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = isOnline;
    _updateOnlineState(results);

    if (!wasOnline && isOnline) {
      debugPrint('Connectivity: Connection restored — triggering sync');
      _triggerSync(reason: 'connection_restored');
    } else if (wasOnline && !isOnline) {
      debugPrint('Connectivity: Connection lost');
    }
  }

  static void _updateOnlineState(List<ConnectivityResult> results) {
    isOnline = results.any((r) => r != ConnectivityResult.none);
  }

  // ── Sync logic ────────────────────────────────────────────────────────────

  /// Trigger a sync if the cooldown period has elapsed.
  static Future<void> _triggerSync({String? reason}) async {
    if (!supabaseReady || currentUserId == null) return;

    // Respect cooldown
    if (_lastSyncTime != null &&
        DateTime.now().difference(_lastSyncTime!) < _syncCooldown) {
      debugPrint('Connectivity: Sync skipped (cooldown) — reason: $reason');
      return;
    }

    try {
      _lastSyncTime = DateTime.now();
      debugPrint('Connectivity: Starting auto-sync — reason: $reason');
      await SupabaseSyncService.syncNow();
      debugPrint('Connectivity: Auto-sync completed');
    } catch (e) {
      debugPrint('Connectivity: Auto-sync failed: $e');
    }
  }

  /// Called after any write operation (add/update/delete) to trigger sync.
  /// Uses fire-and-forget to avoid blocking the UI.
  static void onWriteOperation(String entity) {
    if (!isOnline || !supabaseReady || currentUserId == null) return;
    _triggerSync(reason: '${entity}_write');
  }

  // ── Periodic sync ────────────────────────────────────────────────────────

  static void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_periodicInterval, (_) {
      if (isOnline && supabaseReady && currentUserId != null) {
        _triggerSync(reason: 'periodic');
      }
    });
  }

  /// Force a sync now (ignoring cooldown). Used for manual pull-to-refresh.
  static Future<void> forceSyncNow() async {
    _lastSyncTime = null;
    await _triggerSync(reason: 'manual');
  }

  // ── Lifecycle hooks ──────────────────────────────────────────────────────

  /// Called when the user logs in.
  static Future<void> onLogin() async {
    await initialize();
    // Trigger initial sync after login
    if (isOnline && supabaseReady) {
      _triggerSync(reason: 'login');
    }
  }

  /// Called when the user logs out.
  static void onLogout() {
    dispose();
  }
}
