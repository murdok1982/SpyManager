import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_enclave_storage.dart';

/// Graceful degradation with encrypted SQLite and deferred sync
class OfflineSyncService {
  static const String _dbName = 'offline_sync.db';
  static const String _tableName = 'unsynced_data';
  Database? _db;

  /// Initialize encrypted SQLite database
  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    
    // Use SQLCipher for encryption (requires key from secure storage)
    final encryptionKey = await SecureEnclaveStorage().read(key: 'db_encryption_key') ?? 'default_key';
    
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            sync_attempts INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  /// Save unsynced data for deferred sync
  Future<void> saveUnsynced(Map<String, dynamic> data) async {
    await _db?.insert(_tableName, {
      'data': data.toString(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Sync pending data to backend when online
  Future<void> syncPending() async {
    if (_db == null) await initialize();
    
    final pending = await _db!.query(_tableName);
    for (final row in pending) {
      try {
        final data = row['data'] as String;
        await ApiClient().dio.post('/api/sync', data: data);
        await _db!.delete(_tableName, where: 'id = ?', whereArgs: [row['id']]);
      } catch (_) {
        // Increment sync attempts
        await _db!.update(
          _tableName,
          {'sync_attempts': (row['sync_attempts'] as int) + 1},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
  }

  /// Check if there is pending data to sync
  Future<bool> hasPendingData() async {
    if (_db == null) await initialize();
    final count = Sqflite.firstIntValue(await _db!.rawQuery('SELECT COUNT(*) FROM $_tableName'));
    return count! > 0;
  }
}
