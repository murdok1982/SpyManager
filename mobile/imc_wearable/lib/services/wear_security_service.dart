import 'dart:io';
import 'package:trust_fall/trust_fall.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WearSecurityService {
  WearSecurityService._();

  static final WearSecurityService instance = WearSecurityService._();

  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  Future<bool> performSecurityCheck() async {
    try {
      final isJailbroken = await TrustFall.isJailBroken;
      if (isJailbroken == true) return false;

      final isRealDevice = await TrustFall.isRealDevice;
      if (isRealDevice == false) return false;

      if (Platform.isAndroid) {
        final result = await Process.run('ps', ['-A']);
        final output = result.stdout.toString();
        if (output.contains('frida')) return false;
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> handleSecurityBreach() async {
    await _storage.deleteAll();
    if (Platform.isAndroid) {
      try {
        await Process.run('pm', ['clear', 'com.imc.wearable']);
      } catch (_) {}
    }
  }

  Future<void> saveDeadManHours(int hours) async {
    await _storage.write(key: 'dead_man_hours', value: hours.toString());
  }

  Future<int> getDeadManHours() async {
    final value = await _storage.read(key: 'dead_man_hours');
    return int.tryParse(value ?? '') ?? 12;
  }

  Future<void> updateCheckIn() async {
    await _storage.write(
      key: 'last_checkin',
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<bool> shouldTriggerDeadMan() async {
    final value = await _storage.read(key: 'last_checkin');
    if (value == null) return false;

    final lastCheckIn = DateTime.tryParse(value);
    if (lastCheckIn == null) return false;

    final hours = await getDeadManHours();
    return DateTime.now().difference(lastCheckIn) > Duration(hours: hours);
  }

  Future<void> setCovertChannelsEnabled(bool enabled) async {
    await _storage.write(key: 'covert_enabled', value: enabled.toString());
  }

  Future<bool> getCovertChannelsEnabled() async {
    final value = await _storage.read(key: 'covert_enabled');
    return value == 'true';
  }

  Future<void> saveBehavioralData(Map<String, dynamic> data) async {
    final existing = await _storage.read(key: 'behavioral_data') ?? '{}';
    await _storage.write(key: 'behavioral_data', value: data.toString());
  }
}
