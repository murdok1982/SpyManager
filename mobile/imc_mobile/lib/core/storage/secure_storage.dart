import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants.dart';

class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: AppConstants.keyAuthToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return _storage.read(key: AppConstants.keyAuthToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.keyRefreshToken);
  }

  Future<void> saveAgentId(String agentId) async {
    await _storage.write(key: AppConstants.keyAgentId, value: agentId);
  }

  Future<String?> getAgentId() async {
    return _storage.read(key: AppConstants.keyAgentId);
  }

  Future<void> saveClassificationLevel(String level) async {
    await _storage.write(key: AppConstants.keyClassificationLevel, value: level);
  }

  Future<String?> getClassificationLevel() async {
    return _storage.read(key: AppConstants.keyClassificationLevel);
  }

  /// Wipes all stored credentials — used in ABORT MISSION
  Future<void> wipeAll() async {
    await _storage.deleteAll();
  }

  Future<bool> hasValidSession() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
