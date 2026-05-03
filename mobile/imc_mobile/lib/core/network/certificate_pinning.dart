import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_certificate_pinning/dio_certificate_pinning.dart';

class CertificatePinning {
  CertificatePinning._();

  static const List<String> _pinnedCertificates = [
    'sha256/f0KWoWwVfFzRzbGQrNnCxz7eByqRZ8ulLFasVZ8MYk=',
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];

  static Interceptor getInterceptor() {
    return CertificatePinningInterceptor(
      allowedSHAFingerprints: _pinnedCertificates,
      timeout: const Duration(seconds: 10),
      onError: (error) {
        print('[SECURITY] Certificate pinning failed: $error');
      },
    );
  }

  static SecurityContext getSecurityContext() {
    final context = SecurityContext();
    return context;
  }
}
