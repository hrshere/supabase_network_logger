import 'dart:convert';

class NetworkLog {
  final String id; // Unique ID for deduplication
  final DateTime createdAt;

  /// API_FAILURE, INTERNET_FAILURE, VALIDATION_FAILURE, APP_EXCEPTION, etc.
  final String errorType;

  final String? url;
  final String? method;
  final int? statusCode;

  /// Renamed from requestBody
  final dynamic requestData;

  /// Renamed from responseBody
  final dynamic apiResponseData;

  final String? errorMessage;
  final String? stackTrace;
  final String? traceId;

  final Map<String, dynamic>? deviceInfo;

  /// Renamed from appInfo
  final Map<String, dynamic>? appVersion;

  final Map<String, dynamic>? extra;

  final String? screenName;

  /// New fields
  final String? tag;
  final String? userId;
  final String? mobile;

  NetworkLog({
    required this.id,
    required this.createdAt,
    required this.errorType,
    this.url,
    this.method,
    this.statusCode,
    this.requestData,
    this.apiResponseData,
    this.errorMessage,
    this.stackTrace,
    this.traceId,
    this.deviceInfo,
    this.appVersion,
    this.extra,
    this.screenName,
    this.tag,
    this.userId,
    this.mobile,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'error_type': errorType,
      'url': url,
      'method': method,
      'status_code': statusCode,
      'request_data': requestData != null ? _safeJsonEncode(requestData) : null,
      'api_response_data':
          apiResponseData != null ? _safeJsonEncode(apiResponseData) : null,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'trace_id': traceId,
      'device_info': deviceInfo,
      'app_version': appVersion,
      'extra': extra,
      'screen_name': screenName,
      'tag': tag,
      'user_id': userId,
      'mobile': mobile,
    };
  }

  factory NetworkLog.fromJson(Map<String, dynamic> json) {
    return NetworkLog(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      errorType: json['error_type'] as String,
      url: json['url'] as String?,
      method: json['method'] as String?,
      statusCode: json['status_code'] as int?,
      requestData: json['request_data'],
      apiResponseData: json['api_response_data'],
      errorMessage: json['error_message'] as String?,
      stackTrace: json['stack_trace'] as String?,
      traceId: json['trace_id'] as String?,
      deviceInfo: json['device_info'] != null
          ? Map<String, dynamic>.from(json['device_info'])
          : null,
      appVersion: json['app_version'] != null
          ? Map<String, dynamic>.from(json['app_version'])
          : null,
      extra: json['extra'] != null
          ? Map<String, dynamic>.from(json['extra'])
          : null,
      screenName: json['screen_name'] as String?,
      tag: json['tag'] as String?,
      userId: json['user_id'] as String?,
      mobile: json['mobile'] as String?,
    );
  }

  static dynamic _safeJsonEncode(dynamic value) {
    try {
      return jsonDecode(jsonEncode(value));
    } catch (_) {
      return value.toString();
    }
  }

  NetworkLog copyWith({
    String? id,
    DateTime? createdAt,
    String? errorType,
    String? url,
    String? method,
    int? statusCode,
    dynamic requestData,
    dynamic apiResponseData,
    String? errorMessage,
    String? stackTrace,
    String? traceId,
    Map<String, dynamic>? deviceInfo,
    Map<String, dynamic>? appVersion,
    Map<String, dynamic>? extra,
    String? screenName,
    String? tag,
    String? userId,
    String? mobile,
  }) {
    return NetworkLog(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      errorType: errorType ?? this.errorType,
      url: url ?? this.url,
      method: method ?? this.method,
      statusCode: statusCode ?? this.statusCode,
      requestData: requestData ?? this.requestData,
      apiResponseData: apiResponseData ?? this.apiResponseData,
      errorMessage: errorMessage ?? this.errorMessage,
      stackTrace: stackTrace ?? this.stackTrace,
      traceId: traceId ?? this.traceId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
      extra: extra ?? this.extra,
      screenName: screenName ?? this.screenName,
      tag: tag ?? this.tag,
      userId: userId ?? this.userId,
      mobile: mobile ?? this.mobile,
    );
  }
}
