import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import '../constants.dart';

class SecureEnclaveStorage {
  SecureEnclaveStorage._();

  static final SecureEnclaveStorage instance = SecureEnclaveStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'imc_secure_enclave',
    ),
  );

  static const String _masterKeyTag = 'imc_master_key';
  static const String _encryptionKeyTag = 'imc_encryption_key';

  Future<String?> _getOrCreateMasterKey() async {
    var masterKey = await _storage.read(key: _masterKeyTag);
    if (masterKey == null) {
      final keyBytes = encrypt.SecureRandom(32).bytes;
      masterKey = base64Encode(keyBytes);
      await _storage.write(key: _masterKeyTag, value: masterKey);
    }
    return masterKey;
  }

  Future<encrypt.Encrypter> _getEncrypter() async {
    final masterKey = await _getOrCreateMasterKey();
    final key = encrypt.Key.fromBase64(masterKey!);
    return encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
  }

  Future<String> encryptData(String plainText) async {
    final encrypter = await _getEncrypter();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  Future<String> decryptData(String encryptedText) async {
    final parts = encryptedText.split(':');
    if (parts.length != 2) throw FormatException('Invalid encrypted data');

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypter = await _getEncrypter();
    final decrypted = encrypter.decrypt64(parts[1], iv: iv);
    return decrypted;
  }

  Future<void> saveAuthToken(String token) async {
    final encrypted = await encryptData(token);
    await _storage.write(key: AppConstants.keyAuthToken, value: encrypted);
  }

  Future<String?> getAuthToken() async {
    final encrypted = await _storage.read(key: AppConstants.keyAuthToken);
    if (encrypted == null) return null;
    return decryptData(encrypted);
  }

  Future<void> saveRefreshToken(String token) async {
    final encrypted = await encryptData(token);
    await _storage.write(key: AppConstants.keyRefreshToken, value: encrypted);
  }

  Future<String?> getRefreshToken() async {
    final encrypted = await _storage.read(key: AppConstants.keyRefreshToken);
    if (encrypted == null) return null;
    return decryptData(encrypted);
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

  Future<void> saveDuressPin(String pin) async {
    final encrypted = await encryptData(pin);
    await _storage.write(key: 'duress_pin', value: encrypted);
  }

  Future<String?> getDuressPin() async {
    final encrypted = await _storage.read(key: 'duress_pin');
    if (encrypted == null) return null;
    return decryptData(encrypted);
  }

  Future<void> saveDeadManHours(int hours) async {
    await _storage.write(key: 'dead_man_hours', value: hours.toString());
  }

  Future<int> getDeadManHours() async {
    final value = await _storage.read(key: 'dead_man_hours');
    return int.tryParse(value ?? '') ?? 24;
  }

  Future<void> saveLastCheckIn() async {
    final now = DateTime.now().toIso8601String();
    await _storage.write(key: 'last_checkin', value: now);
  }

  Future<DateTime?> getLastCheckIn() async {
    final value = await _storage.read(key: 'last_checkin');
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<void> wipeAll() async {
    await _storage.deleteAll();
  }

  Future<bool> hasValidSession() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveBehavioralBaseline(Map<String, dynamic> baseline) async {
    final json = jsonEncode(baseline);
    final encrypted = await encryptData(json);
    await _storage.write(key: 'behavioral_baseline', value: encrypted);
  }

  Future<Map<String, dynamic>?> getBehavioralBaseline() async {
    final encrypted = await _storage.read(key: 'behavioral_baseline');
    if (encrypted == null) return null;
    final json = await decryptData(encrypted);
    return jsonDecode(json) as Map<String, dynamic>;
  }
}
