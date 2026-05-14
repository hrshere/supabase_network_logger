import 'package:dio/dio.dart';
import '../../supabase_network_logger.dart';

typedef CustomErrorParser = String? Function(Response response);

class SupabaseLoggerInterceptor extends Interceptor {
  final CustomErrorParser? customErrorParser;
  final List<String> maskedKeys;

  SupabaseLoggerInterceptor({
    this.customErrorParser,
    this.maskedKeys = const ['password', 'token', 'authorization', 'secret', 'fcm_token'],
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    SupabaseNetworkLogger.logFailure(
      type: 'API_FAILURE',
      url: err.requestOptions.uri.toString(),
      method: err.requestOptions.method,
      statusCode: err.response?.statusCode,
      requestBody: _maskData(err.requestOptions.data),
      responseBody: err.response?.data,
      errorMessage: err.message,
      stackTrace: err.stackTrace.toString(),
    );
    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (customErrorParser != null) {
      final customError = customErrorParser!(response);
      if (customError != null) {
        SupabaseNetworkLogger.logFailure(
          type: 'API_FAILURE',
          url: response.requestOptions.uri.toString(),
          method: response.requestOptions.method,
          statusCode: response.statusCode,
          requestBody: _maskData(response.requestOptions.data),
          responseBody: response.data,
          errorMessage: customError,
        );
      }
    }
    super.onResponse(response, handler);
  }

  dynamic _maskData(dynamic data) {
    if (data is Map) {
      final masked = Map<String, dynamic>.from(data);
      for (var key in maskedKeys) {
        if (masked.containsKey(key)) {
          masked[key] = '***';
        }
      }
      return masked;
    }
    return data;
  }
}
