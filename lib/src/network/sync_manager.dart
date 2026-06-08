import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase_network_logger.dart';
import '../storage/log_storage.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  bool _isSyncing = false;
  int _consecutiveFailures = 0;
  DateTime? _circuitBrokenUntil;
  Timer? _batchTimer;

  // Configuration
  int batchSize = 10;
  Duration batchInterval = const Duration(seconds: 30);
  int maxRetries = 3;
  Duration circuitBreakDuration = const Duration(minutes: 5);

  void start() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(batchInterval, (_) => sync());

    // Auto-sync when internet restored
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        sync();
      }
    });
  }

  bool get isCircuitOpen {
    if (_circuitBrokenUntil == null) return false;
    if (DateTime.now().isAfter(_circuitBrokenUntil!)) {
      _circuitBrokenUntil = null;
      _consecutiveFailures = 0;
      return false;
    }
    return true;
  }

  Future<void> sync() async {
    if (_isSyncing || isCircuitOpen) return;

    final logs = LogStorage.getAllLogs();
    if (logs.isEmpty) return;

    _isSyncing = true;
    debugPrint('🔄 SupabaseLogger: Syncing ${logs.length} logs...');

    try {
      final client = Supabase.instance.client;

      // We send all logs in one batch request (Deduplication handled by 'id' primary key)
      final payload = logs.map((l) => l.toJson()).toList();

      await client.from(SupabaseNetworkLogger.tableName).upsert(payload);

      // Success: Clear storage and reset circuit
      await LogStorage.deleteLogs(logs.map((l) => l.id).toList());
      _consecutiveFailures = 0;
      _circuitBrokenUntil = null;
      debugPrint('✅ SupabaseLogger: Sync completed');
    } catch (e) {
      _consecutiveFailures++;
      debugPrint(
          '❌ SupabaseLogger: Sync failed ($_consecutiveFailures/$maxRetries): $e');

      if (_consecutiveFailures >= maxRetries) {
        _circuitBrokenUntil = DateTime.now().add(circuitBreakDuration);
        debugPrint('⚠️ SupabaseLogger: Circuit Breaker OPEN. Waiting 5 mins.');
      }
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _batchTimer?.cancel();
  }
}
