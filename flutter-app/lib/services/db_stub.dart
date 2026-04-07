// ─────────────────────────────────────────────────────────────────────────────
// db_stub.dart
// ─────────────────────────────────────────────────────────────────────────────
//
// Database backend stub for web platforms (and any platform without dart:io).
// All operations are no-ops – the app falls back to in-memory storage.
//
// This file is only compiled when dart:io is NOT available (web).

/// Whether the native database was successfully initialized.
/// Always false in the stub.
bool nativeDbAvailable = false;

/// Attempt to initialize the native database.
/// Always a no-op in the stub.
Future<void> initNativeDb() async {
  nativeDbAvailable = false;
}

/// Query a table – returns empty list in stub.
Future<List<Map<String, dynamic>>> nativeQuery(
  String table, {
  String? orderBy,
  String? where,
  List<Object?>? whereArgs,
}) async {
  return [];
}

/// Insert a row – returns -1 in stub.
Future<int> nativeInsert(String table, Map<String, Object?> values) async {
  return -1;
}

/// Update rows – returns 0 in stub.
Future<int> nativeUpdate(
  String table,
  Map<String, Object?> values, {
  String? where,
  List<Object?>? whereArgs,
}) async {
  return 0;
}

/// Delete rows – returns 0 in stub.
Future<int> nativeDelete(
  String table, {
  String? where,
  List<Object?>? whereArgs,
}) async {
  return 0;
}

/// Execute raw SQL – no-op in stub.
Future<void> nativeExec(String sql, [List<Object?>? args]) async {
  // no-op
}
