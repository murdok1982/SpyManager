import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:trust_fall/trust_fall.dart';
import '../storage/secure_storage.dart';
import '../../services/imc_api_service.dart';

class AntiTamperService {
  AntiTamperService._();

  static final AntiTamperService instance = AntiTamperService._();

  static const String _fridaPorts = '27042,27043,6500';
  static const String _fridaProcesses = 'frida-server,frida-agent,frida-helper';

  Future<SecurityCheckResult> performSecurityCheck() async {
    final results = <String>[];

    if (kDebugMode) {
      results.add('DEBUG_MODE_ENABLED');
    }

    try {
      final isJailbroken = await TrustFall.isJailBroken;
      if (isJailbroken == true) {
        results.add('DEVICE_COMPROMISED');
      }
    } catch (_) {}

    try {
      final isRealDevice = await TrustFall.isRealDevice;
      if (isRealDevice == false) {
        results.add('EMULATOR_DETECTED');
      }
    } catch (_) {}

    try {
      final isDevMode = await TrustFall.isDevelopmentModeEnable;
      if (isDevMode == true) {
        results.add('DEVELOPER_MODE_ENABLED');
      }
    } catch (_) {}

    if (Platform.isAndroid) {
      final fridaDetected = await _detectFridaAndroid();
      if (fridaDetected) {
        results.add('FRIDA_DETECTED');
      }
    }

    return SecurityCheckResult(
      isSecure: results.isEmpty,
      threats: results,
    );
  }

  Future<bool> _detectFridaAndroid() async {
    try {
      final result = await Process.run('ps', ['-A']);
      final output = result.stdout.toString();
      final processes = _fridaProcesses.split(',');
      for (final process in processes) {
        if (output.contains(process)) {
          return true;
        }
      }

      for (final port in _fridaPorts.split(',')) {
        final netstat = await Process.run('netstat', ['-an']);
        if (netstat.stdout.toString().contains(':$port ')) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> handleSecurityBreach(String agentId) async {
    try {
      await IMCApiService.instance.notifySecurityBreach(
        agentId: agentId,
        threats: ['SECURITY_BREACH_DETECTED'],
      );
    } catch (_) {}

    await SecureStorageService.instance.wipeAll();
  }
}

class SecurityCheckResult {
  const SecurityCheckResult({
    required this.isSecure,
    required this.threats,
  });

  final bool isSecure;
  final List<String> threats;
}
