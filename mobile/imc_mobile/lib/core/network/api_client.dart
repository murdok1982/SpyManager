import 'package:dio/dio.dart';
import '../constants.dart';
import 'interceptors.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Client': 'imc-mobile/1.0',
      },
    ),
  )
    ..interceptors.add(AuthInterceptor())
    ..interceptors.add(RetryInterceptor());
}
