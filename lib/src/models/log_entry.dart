import 'dart:convert';

class NetworkLog {
  final String id; // Unique ID for deduplication
  final DateTime createdAt;
  final String errorType; // 'API_FAILURE', 'INTERNET_FAILURE', 'VALIDATION_FAILURE'
  final String? url;
  final String? method;
  final int? statusCode;
  final dynamic requestBody;
  final dynamic responseBody;
  final String? errorMessage;
  final String? stackTrace;
  final String? traceId; // Correlation ID
  final Map<String, dynamic>? deviceInfo;
  final Map<String, dynamic>? appInfo;
  final Map<String, dynamic>? extra;
  final String? screenName;

  NetworkLog({
    required this.id,
    required this.createdAt,
    required this.errorType,
    this.url,
    this.method,
    this.statusCode,
    this.requestBody,
    this.responseBody,
    this.errorMessage,
    this.stackTrace,
    this.traceId,
    this.deviceInfo,
    this.appInfo,
    this.extra,
    this.screenName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'error_type': errorType,
      'url': url,
      'method': method,
      'status_code': statusCode,
      'request_body': requestBody != null ? _safeJsonEncode(requestBody) : null,
      'response_body': responseBody != null ? _safeJsonEncode(responseBody) : null,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'trace_id': traceId,
      'device_info': deviceInfo,
      'app_info': appInfo,
      'extra': extra,
      'screen_name': screenName,
    };
  }

  factory NetworkLog.fromJson(Map<String, dynamic> json) {
    return NetworkLog(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      errorType: json['error_type'],
      url: json['url'],
      method: json['method'],
      statusCode: json['status_code'],
      requestBody: json['request_body'],
      responseBody: json['response_body'],
      errorMessage: json['error_message'],
      stackTrace: json['stack_trace'],
      traceId: json['trace_id'],
      deviceInfo: json['device_info'] != null
          ? Map<String, dynamic>.from(json['device_info'])
          : null,
      appInfo: json['app_info'] != null
          ? Map<String, dynamic>.from(json['app_info'])
          : null,
      extra: json['extra'] != null
          ? Map<String, dynamic>.from(json['extra'])
          : null,
      screenName: json['screen_name'],
    );
  }

  static dynamic _safeJsonEncode(dynamic value) {
    try {
      return jsonDecode(jsonEncode(value));
    } catch (_) {
      return value.toString();
    }
  }
}
