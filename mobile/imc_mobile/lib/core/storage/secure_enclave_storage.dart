import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';

/// Secure storage using Android Keystore and iOS Secure Enclave
class SecureEnclaveStorage {
  static const MethodChannel _channel = MethodChannel('com.spymanager.secure_enclave');
  static SecureEnclaveStorage? _instance;

  factory SecureEnclaveStorage() => _instance ??= SecureEnclaveStorage._internal();
  
  SecureEnclaveStorage._internal();

  /// Read value from secure storage
  Future<String?> read({required String key}) async {
    try {
      if (Platform.isAndroid) {
        return await _channel.invokeMethod('readFromKeystore', {'key': key});
      } else if (Platform.isIOS) {
        return await _channel.invokeMethod('readFromSecureEnclave', {'key': key});
      }
      throw UnsupportedError('Unsupported platform');
    } catch (e) {
      debugPrint('Secure storage read error: $e');
      return null;
    }
  }

  /// Write value to secure storage
  Future<void> write({required String key, required String value}) async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('writeToKeystore', {'key': key, 'value': value});
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('writeToSecureEnclave', {'key': key, 'value': value});
      }
    } catch (e) {
      debugPrint('Secure storage write error: $e');
    }
  }

  /// Delete value from secure storage
  Future<void> delete({required String key}) async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('deleteFromKeystore', {'key': key});
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('deleteFromSecureEnclave', {'key': key});
      }
    } catch (e) {
      debugPrint('Secure storage delete error: $e');
    }
  }

  /// Wipe all data from secure storage
  static Future<void> wipeAll() async {
    try {
      await _channel.invokeMethod('wipeAll');
    } catch (e) {
      debugPrint('Secure storage wipe error: $e');
    }
  }
}
