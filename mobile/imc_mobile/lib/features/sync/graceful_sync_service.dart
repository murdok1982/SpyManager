import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/security/secure_enclave_storage.dart';
import '../services/imc_api_service.dart';

class GracefulSyncService {
  GracefulSyncService._();

  static final GracefulSyncService instance = GracefulSyncService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'imc_offline.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE offline_queue(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            data TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE intel_reports(
            id TEXT PRIMARY KEY,
            agent_id TEXT NOT NULL,
            type TEXT NOT NULL,
            content TEXT NOT NULL,
            classification TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE mesh_messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender_id TEXT NOT NULL,
            message TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            delivered INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> queueForSync({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    await db.insert('offline_queue', {
      'type': type,
      'data': data.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<void> syncWithBackend() async {
    final db = await database;
    final unsynced = await db.query(
      'offline_queue',
      where: 'synced = 0',
    );

    for (final item in unsynced) {
      try {
        final type = item['type'] as String;
        final data = item['data'] as String;

        await IMCApiService.instance.submitIntelReport(
          MobileReport(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            agentId: 'UNKNOWN',
            type: type,
            content: data,
            timestamp: DateTime.now(),
            classification: 'SECRET',
          ),
        );

        await db.update(
          'offline_queue',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      } catch (_) {}
    }
  }

  Future<List<Map<String, dynamic>>> getLocalReports() async {
    final db = await database;
    return db.query('intel_reports');
  }

  Future<void> saveLocalReport({
    required String id,
    required String agentId,
    required String type,
    required String content,
    required String classification,
  }) async {
    final db = await database;
    await db.insert('intel_reports', {
      'id': id,
      'agent_id': agentId,
      'type': type,
      'content': content,
      'classification': classification,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> performSyncIfOnline() async {
    final online = await isOnline();
    if (online) {
      await syncWithBackend();
    }
  }
}
