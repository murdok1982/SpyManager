class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String wearableChannel = 'com.imc.wearable/data';
  static const String appName = 'IMC OPERATIVE';

  // Route names
  static const String routeLogin = '/login';
  static const String routeDashboard = '/dashboard';
  static const String routeCases = '/cases';
  static const String routeCaseDetail = '/cases/:id';
  static const String routeIntel = '/intel';
  static const String routeIntelReport = '/intel/report';
  static const String routeMap = '/map';
  static const String routeEmergency = '/emergency';
  static const String routeWearableSync = '/wearable';
  static const String routeAuditLog = '/audit';

  // Secure storage keys
  static const String keyAuthToken = 'auth_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyAgentId = 'agent_id';
  static const String keyClassificationLevel = 'classification_level';

  // Cover mode
  static const int coverModeTapCount = 3;

  // Emergency
  static const int emergencyCountdownSeconds = 5;

  // Token expiry
  static const Duration accessTokenExpiry = Duration(minutes: 15);
  static const Duration refreshTokenExpiry = Duration(days: 7);

  // API timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Background sync
  static const Duration syncInterval = Duration(minutes: 5);
}
