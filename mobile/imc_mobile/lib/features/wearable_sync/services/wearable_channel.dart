import 'dart:async';

import 'package:flutter/services.dart';

class WearableChannel {
  static const _channel = MethodChannel('com.imc.wearable/data');

  static final WearableChannel _instance = WearableChannel._();

  WearableChannel._();

  factory WearableChannel() => _instance;

  final _biometricController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _sosController = StreamController<void>.broadcast();
  final _reportController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get biometricUpdates =>
      _biometricController.stream;
  Stream<void> get sosActivated => _sosController.stream;
  Stream<Map<String, dynamic>> get quickReports => _reportController.stream;

  void initialize() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'emergencySOS':
          _sosController.add(null);
        case 'biometricUpdate':
          _biometricController
              .add(Map<String, dynamic>.from(call.arguments as Map));
        case 'quickReport':
          _reportController
              .add(Map<String, dynamic>.from(call.arguments as Map));
      }
    });
  }

  Future<void> sendAgentStatus(String status, String? caseId) async {
    await _channel.invokeMethod<void>('sendToWear', {
      'type': 'STATUS_UPDATE',
      'agentStatus': status,
      'caseId': caseId ?? '',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> sendCaseUpdate(String caseId, String caseName) async {
    await _channel.invokeMethod<void>('sendToWear', {
      'type': 'CASE_UPDATE',
      'caseId': caseId,
      'caseName': caseName,
    });
  }

  void dispose() {
    _biometricController.close();
    _sosController.close();
    _reportController.close();
  }
}
