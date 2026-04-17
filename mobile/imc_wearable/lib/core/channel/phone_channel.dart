import 'package:flutter/services.dart';
import '../../services/wear_data_service.dart';

class PhoneChannel {
  static const _channel = MethodChannel('com.imc.wearable/data');

  void initialize(WearDataService dataService) {
    _channel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'sendToWear':
            if (call.arguments is! Map) return;
            final args = Map<String, dynamic>.from(call.arguments as Map);
            final type = args['type'];
            if (type is! String) return;
            switch (type) {
              case 'STATUS_UPDATE':
                final status = args['agentStatus'];
                if (status is String && status.isNotEmpty) {
                  dataService.updateAgentStatus(status);
                }
                final caseId = args['caseId'];
                if (caseId is String) dataService.updateCaseId(caseId);
              case 'CASE_UPDATE':
                final caseId = args['caseId'];
                if (caseId is String) dataService.updateCaseId(caseId);
            }
        }
      } catch (_) {
        // Canal no autentica al emisor — ignorar payloads malformados
        // sin crashear el proceso del wearable
      }
    });
  }

  Future<void> sendEmergencyToPhone() async {
    await _channel.invokeMethod<void>('emergencySOS', {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> sendQuickReport(String reportType) async {
    await _channel.invokeMethod<void>('quickReport', {
      'type': reportType,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> sendBiometricUpdate(Map<String, dynamic> data) async {
    await _channel.invokeMethod<void>('biometricUpdate', data);
  }
}
