import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';

/// Anti-Debug y Anti-Tamper para SpyManager
/// Detecta debugging, emuladores y Frama/Frida
class AntiTamper {
  static const _storage = FlutterSecureStorage();
  static const _channel = MethodChannel('com.spymanager/security');

  /// Verificar si la app está siendo depurada o manipulada
  static Future<bool> isCompromised() async {
    if (kDebugMode) return false; // Permitir en desarrollo

    try {
      // Verificar debugger
      if (await _isDebuggerAttached()) return true;

      // Verificar emulador
      if (await _isRunningOnEmulator()) return true;

      // Verificar Frida (Android)
      if (Platform.isAndroid && await _isFridaDetected()) return true;

      // Verificar integridad de la app
      if (!await _verifyAppIntegrity()) return true;

      return false;
    } catch (e) {
      debugPrint('AntiTamper check error: $e');
      return true; // En caso de duda, asumir comprometido
    }
  }

  static Future<bool> _isDebuggerAttached() async {
    try {
      final result = await _channel.invokeMethod<bool>('isDebuggerAttached');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _isRunningOnEmulator() async {
    if (Platform.isAndroid) {
      return Platform.environment.containsKey('ANDROID_EMULATOR_HOST') ||
          Platform.environment.containsKey('ANDROID_SDK_ROOT') &&
              Platform.environment['ANDROID_SDK_ROOT']?.contains('emulator') == true;
    } else if (Platform.isIOS) {
      return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
          Platform.environment.containsKey('SIMULATOR_RUNTIME_VERSION');
    }
    return false;
  }

  static Future<bool> _isFridaDetected() async {
    try {
      // Verificar procesos sospechosos
      final result = await Process.run('ps', ['-A']);
      if (result.stdout.toString().toLowerCase().contains('frida')) return true;

      // Verificar puertos comunes de Frida
      final ports = await Process.run('netstat', ['-an']);
      if (ports.stdout.toString().contains(':27042')) return true;

      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _verifyAppIntegrity() async {
    try {
      final result = await _channel.invokeMethod<bool>('verifyIntegrity');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Ejecutar acciones de emergencia: limpiar datos y notificar backend
  static Future<void> executeWipe(ApiClient apiClient) async {
    try {
      // Notificar al backend
      await apiClient.post('/api/v1/security/compromised', data: {
        'timestamp': DateTime.now().toIso8601String(),
        'reason': 'anti_tamper_triggered'
      }).catchError((_) {});

      // Limpiar almacenamiento seguro
      await _storage.deleteAll();

      // Eliminar datos locales
      // TODO: Implementar limpieza de SQLite local

      debugPrint('WIPE COMPLETED: Datos eliminados por compromiso detectado');
    } catch (e) {
      debugPrint('Error during wipe: $e');
    }
  }
}
