import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart'; // 👈 Added this
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/models/log_entry.dart';
import 'src/network/sync_manager.dart';
import 'src/storage/log_storage.dart';
import 'src/utils/device_info_util.dart';

export 'src/interceptors/dio_interceptor.dart';
export 'src/models/log_entry.dart';

class SupabaseNetworkLogger {
  static String? _appName;
  static String? _currentScreen;
  static String Function()? _screenProvider;
  static Map<String, dynamic>? _cachedDeviceInfo;
  static Map<String, dynamic>? _cachedAppInfo;
  static Map<String, dynamic>? _globalExtra;

  /// Initialize the logger. Should be called in main().
  static Future<void> init({
    required String appName,
    required String supabaseUrl,
    required String supabaseAnonKey,
    String Function()? screenProvider,
    Map<String, dynamic>? globalExtra, // 👈 Added global metadata support
  }) async {
    _appName = appName;
    _screenProvider = screenProvider;
    _globalExtra = globalExtra;

    // Initialize Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    await LogStorage.init();
    SyncManager().start();

    // Force sync when app goes to background
    WidgetsBinding.instance.addObserver(_LifecycleObserver());

    // Prefetch info
    _cachedDeviceInfo = await DeviceInfoUtil.getDeviceInfo();
    _cachedAppInfo = await DeviceInfoUtil.getAppInfo();
  }

  /// Manually log a failure (API, Internet, or Validation)
  static Future<void> logFailure({
    required String
        type, // 'API_FAILURE', 'INTERNET_FAILURE', 'VALIDATION_FAILURE'
    String? url,
    String? method,
    int? statusCode,
    dynamic requestBody,
    dynamic responseBody,
    String? errorMessage,
    String? stackTrace,
    String? traceId,
    String? screenName,
    Map<String, dynamic>? extra,
    String? tag,
    String? userId,
    String? mobile,
  }) async {
    final resolvedScreenName = screenName ??
        _screenProvider?.call() ??
        _currentScreen ??
        'App Launch'; // 👈 Fallback for early errors

    final log = NetworkLog(
      id: _generateUniqueId(url, errorMessage),
      createdAt: DateTime.now().toUtc(),
      errorType: type,
      url: url,
      method: method,
      statusCode: statusCode,
      requestData: requestBody,
      apiResponseData: responseBody,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      traceId: traceId,
      screenName: resolvedScreenName,
      deviceInfo: _cachedDeviceInfo,
      appVersion: _cachedAppInfo,
      extra: {
        'app_name': _appName,
        ...?_globalExtra, // 👈 Global metadata (Flavor, Env, etc.)
        ...?extra, // 👈 Local metadata (specific to this log)
      },
      tag: tag,
      userId: userId,
      mobile: mobile,
    );

    await LogStorage.saveLog(log);

    // Try to sync if it's a critical error or internet restored
    if (LogStorage.count >= SyncManager().batchSize) {
      SyncManager().sync();
    }
  }

  static String _generateUniqueId(String? url, String? error) {
    final content = '${DateTime.now().microsecondsSinceEpoch}-$url-$error';
    return md5.convert(utf8.encode(content)).toString();
  }

  static Future<void> forceSync() => SyncManager().sync();

  /// Internal setter for the current screen (used by the Observer)
  static void _setCurrentScreen(String? name) => _currentScreen = name;
}

/// A [NavigatorObserver] that automatically tracks the current screen name
/// for the [SupabaseNetworkLogger].
class SupabaseLoggerObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    SupabaseNetworkLogger._setCurrentScreen(route.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    SupabaseNetworkLogger._setCurrentScreen(previousRoute?.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    SupabaseNetworkLogger._setCurrentScreen(newRoute?.settings.name);
  }
}

/// Internal observer to trigger sync when the app goes to the background
class _LifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // User minimized or closed the app, try to flush logs
      SupabaseNetworkLogger.forceSync();
    }
  }
}
