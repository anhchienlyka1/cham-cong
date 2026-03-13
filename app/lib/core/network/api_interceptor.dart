import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants/app_constants.dart';

/// Dio interceptor for auth token injection and logging.
class ApiInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  ApiInterceptor(this._prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Inject auth token
    final token = _prefs.getString(AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    _logger.d('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _logger.d('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      '✖ ${err.response?.statusCode} ${err.requestOptions.uri}',
      error: err.message,
    );

    // Handle 401 - could trigger token refresh here
    if (err.response?.statusCode == 401) {
      // TODO: Implement token refresh logic
    }

    handler.next(err);
  }
}
