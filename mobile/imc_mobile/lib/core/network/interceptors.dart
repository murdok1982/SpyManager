import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import '../constants.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorageService.instance.getAuthToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _attemptTokenRefresh(err.requestOptions);
      if (refreshed != null) {
        handler.resolve(refreshed);
        return;
      }
      await SecureStorageService.instance.wipeAll();
    }
    handler.next(err);
  }

  Future<Response?> _attemptTokenRefresh(RequestOptions originalRequest) async {
    final refreshToken = await SecureStorageService.instance.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newToken = response.data['access_token'] as String?;
      if (newToken == null) return null;

      await SecureStorageService.instance.saveAuthToken(newToken);
      originalRequest.headers['Authorization'] = 'Bearer $newToken';

      return await dio.fetch(originalRequest);
    } catch (_) {
      return null;
    }
  }
}

class RetryInterceptor extends Interceptor {
  static const int _maxRetries = 2;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    final shouldRetry = retryCount < _maxRetries &&
        (err.type == DioExceptionType.connectionTimeout ||
         err.type == DioExceptionType.receiveTimeout);

    if (shouldRetry) {
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      await Future.delayed(Duration(seconds: retryCount + 1));
      try {
        final dio = Dio();
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (_) {
        // Fall through to next handler
      }
    }
    handler.next(err);
  }
}
