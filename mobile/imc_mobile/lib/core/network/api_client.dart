import 'package:dio/dio.dart';
import 'cert_pinner.dart';

/// Pre-configured API client with certificate pinning and interceptors
class ApiClient {
  late final Dio _dio;
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://spy-manager-secure.api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    // Apply certificate pinning
    final certPinner = CertPinner(pinnedHashes: [
      'YOUR_PRIMARY_SHA256_PIN_BASE64', // Replace with actual pinned hash
      'YOUR_BACKUP_SHA256_PIN_BASE64',  // Backup pin for cert rotation
    ]);
    certPinner.configureDio(_dio);

    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Attach auth token from secure storage
        final token = await SecureEnclaveStorage().read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Handle token refresh or auth errors
        handler.next(error);
      },
    ));

    // Logging interceptor (disabled in release)
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }
  }

  Dio get dio => _dio;
}
