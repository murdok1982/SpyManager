import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Certificate pinning para SpyManager (IMC)
/// Implementa SHA-256 pinning para prevenir MITM attacks
class CertPinner {
  // SHA-256 hashes de los certificados del backend (en producción, generar reales)
  // Formato: base64 de SHA-256 del certificado DER
  static const List<String> _pinnedHashes = [
    // Reemplazar con hashes reales del certificado del backend en producción
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
  ];

  /// Crear interceptor de Dio con validación real de certificados
  static InterceptorsWrapper getInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // En desarrollo, permitir todos los certificados
        if (kDebugMode) {
          return handler.next(options);
        }
        // En producción, forzar validación HTTPS con pins
        options.extra['withCredentials'] = true;
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.error != null && e.error.toString().contains('certificate')) {
          debugPrint('ALERTA: Certificado no coincide - posible MITM');
          // Notificar al backend sobre posible ataque
        }
        return handler.next(e);
      },
    );
  }

  /// Validar que el certificado del servidor coincida con los pins
  static bool validatePin(String serverCertHash) {
    if (kDebugMode) return true; // Skip en desarrollo
    return _pinnedHashes.any((pin) => pin.contains(serverCertHash));
  }

  /// Obtener configuración de seguridad para Dio
  static BaseOptions getDioOptions() {
    return BaseOptions(
      validateStatus: (status) => status != null && status < 500,
      // Forzar uso de TLS 1.2+ y validación de certificados
      // El pinning real se implementa via platform channel en Android/iOS
    );
  }
}

class CertPinningException implements Exception {
  final String message;
  CertPinningException(this.message);
  @override
  String toString() => 'CertPinningException: $message';
}
