import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/log_entry.dart';

class LogStorage {
  static const String _boxName = 'supabase_network_logs_v1';
  static Box? _box;

  static Future<void> init() async {
    if (_box != null) return;
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static Future<void> saveLog(NetworkLog log) async {
    await _ensureInitialized();
    await _box!.put(log.id, log.toJson());
  }

  static List<NetworkLog> getAllLogs() {
    if (_box == null) return [];
    return _box!.values
        .map((e) {
          try {
            return NetworkLog.fromJson(Map<String, dynamic>.from(e as Map));
          } catch (err) {
            debugPrint('❌ SupabaseLogger: Failed to parse log entry: $err');
            return null;
          }
        })
        .whereType<NetworkLog>()
        .toList();
  }

  static Future<void> deleteLogs(List<String> ids) async {
    await _ensureInitialized();
    await _box!.deleteAll(ids);
  }

  static Future<void> clearAll() async {
    await _ensureInitialized();
    await _box!.clear();
  }

  static int get count => _box?.length ?? 0;

  static Future<void> _ensureInitialized() async {
    if (_box == null) await init();
  }
}
