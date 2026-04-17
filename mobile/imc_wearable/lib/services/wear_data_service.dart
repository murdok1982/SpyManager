import 'package:flutter/material.dart';

class WearDataService extends ChangeNotifier {
  String _agentStatus = 'ACTIVE';
  String _caseId = '';
  int? _heartRate;
  int _stressLevel = 0;
  bool _isConnected = false;
  DateTime _lastSync = DateTime.now();

  String get agentStatus => _agentStatus;
  String get caseId => _caseId;
  int? get heartRate => _heartRate;
  int get stressLevel => _stressLevel;
  bool get isConnected => _isConnected;
  DateTime get lastSync => _lastSync;

  Color get statusColor {
    switch (_agentStatus) {
      case 'ACTIVE':
        return const Color(0xFF00FF87);
      case 'COMPROMISED':
        return const Color(0xFFFF2D2D);
      case 'DARK':
        return const Color(0xFFFFB020);
      default:
        return const Color(0xFF7A8B9E);
    }
  }

  void updateAgentStatus(String status) {
    _agentStatus = status;
    _lastSync = DateTime.now();
    notifyListeners();
  }

  void updateCaseId(String caseId) {
    _caseId = caseId;
    notifyListeners();
  }

  void updateBiometrics({int? heartRate, int? stress}) {
    if (heartRate != null) _heartRate = heartRate;
    if (stress != null) _stressLevel = stress.clamp(0, 100);
    notifyListeners();
  }

  void setConnected({required bool connected}) {
    _isConnected = connected;
    notifyListeners();
  }
}
