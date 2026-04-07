// ─────────────────────────────────────────────────────────────────────────────
// supabase_service.dart
// ─────────────────────────────────────────────────────────────────────────────
//
// Central Supabase client initialization.
//
// Replace the values below with your own Supabase project credentials:
//   1. Go to https://supabase.com → Create a project
//   2. Project Settings → API → copy the "Project URL" and "anon public" key
//   3. Run the SQL script from SUPABASE_SETUP.sql in the SQL Editor
//
// Works on ALL platforms: Android, iOS, Web, Windows, macOS, Linux.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── YOUR SUPABASE CREDENTIALS ─────────────────────────────────────────────
// TODO: Replace these with your actual Supabase project credentials.
const String _supabaseUrl = 'https://feabwgfrpsasltufxkyd.supabase.co';    // ← الصق URL الخاص بك
const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZlYWJ3Z2ZycHNhc2x0dWZ4a3lkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU0MTI4NzQsImV4cCI6MjA5MDk4ODg3NH0.9ETvz_IDWly-MRWNeacgYZ9EVmsYQgBnC5OFvr2HVM4';          // ← الصق anon key الخاص بك
// ────────────────────────────────────────────────────────────────────────────

/// Global Supabase client convenience getter.
SupabaseClient get supabase => Supabase.instance.client;

/// Whether Supabase was successfully initialized.
bool supabaseReady = false;

/// Initialize the Supabase client.
///
/// Call this once in main() before runApp().
/// Returns true on success, false on failure.
Future<bool> initSupabase() async {
  try {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    supabaseReady = true;
    debugPrint('Supabase initialized successfully');
    return true;
  } catch (e) {
    debugPrint('Supabase init failed: $e');
    supabaseReady = false;
    return false;
  }
}

/// Returns the currently authenticated user's ID, or null.
String? get currentUserId {
  try {
    return supabase.auth.currentUser?.id;
  } catch (_) {
    return null;
  }
}

/// Returns true if a user is currently signed in.
bool get isSignedIn {
  try {
    return supabase.auth.currentUser != null;
  } catch (_) {
    return false;
  }
}
