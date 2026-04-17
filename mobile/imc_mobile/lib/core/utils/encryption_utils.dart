import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptionError implements Exception {
  const EncryptionError(this.message);
  final String message;
  @override
  String toString() => 'EncryptionError: $message';
}

class EncryptionUtils {
  EncryptionUtils._();

  /// SHA-256 para hashes de integridad (reemplaza el FNV-1a no criptográfico).
  static String generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().toUpperCase();
  }

  /// AES-256-GCM con nonce aleatorio de 12 bytes.
  /// Lanza [EncryptionError] en lugar de retornar plaintext silenciosamente.
  static String encryptField(String plaintext, String keyBase64) {
    final keyBytes = base64Decode(keyBase64);
    if (keyBytes.length < 32) throw const EncryptionError('Key must be 32 bytes');
    final key = Key(Uint8List.fromList(keyBytes.sublist(0, 32)));
    final iv = IV.fromSecureRandom(12);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }

  /// Descifra AES-256-GCM. Lanza [EncryptionError] si el payload es inválido.
  static String decryptField(String ciphertext, String keyBase64) {
    final parts = ciphertext.split(':');
    if (parts.length != 2) throw const EncryptionError('Invalid ciphertext format');
    final keyBytes = base64Decode(keyBase64);
    if (keyBytes.length < 32) throw const EncryptionError('Key must be 32 bytes');
    final key = Key(Uint8List.fromList(keyBytes.sublist(0, 32)));
    final iv = IV(base64Decode(parts[0]));
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    return encrypter.decrypt64(parts[1], iv: iv);
  }

  static String generateReportHash(String content, String agentId, DateTime timestamp) {
    final data = '$agentId|${timestamp.toUtc().toIso8601String()}|$content';
    return generateHash(data);
  }
}
