import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../core/security/secure_enclave_storage.dart';
import '../services/imc_api_service.dart';

const String _deadManTaskName = 'deadManCheckIn';
const String _wipeTaskName = 'deadManWipe';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case _deadManTaskName:
        await _performDeadManCheck();
        break;
      case _wipeTaskName:
        await _performWipe();
        break;
    }
    return Future.value(true);
  });
}

Future<void> _performDeadManCheck() async {
  try {
    final storage = SecureEnclaveStorage.instance;
    final lastCheckIn = await storage.getLastCheckIn();
    final hours = await storage.getDeadManHours();

    if (lastCheckIn == null) return;

    final deadline = lastCheckIn.add(Duration(hours: hours));
    final now = DateTime.now();

    if (now.isAfter(deadline)) {
      await _notifyCommand();
      await _performWipe();
    } else {
      final agentId = await storage.getAgentId();
      if (agentId != null) {
        await IMCApiService.instance.sendDeadManCheckIn(agentId: agentId);
      }
    }
  } catch (_) {}
}

Future<void> _notifyCommand() async {
  try {
    final storage = SecureEnclaveStorage.instance;
    final agentId = await storage.getAgentId();
    if (agentId == null) return;

    await IMCApiService.instance.sendEmergencySOS(
      agentId: agentId,
      latitude: 0.0,
      longitude: 0.0,
    );
  } catch (_) {}
}

Future<void> _performWipe() async {
  try {
    await SecureEnclaveStorage.instance.wipeAll();
    if (Platform.isAndroid) {
      await Process.run('pm', ['clear', 'com.imc.mobile']);
    }
  } catch (_) {}
}

class DeadManService {
  DeadManService._();

  static final DeadManService instance = DeadManService._();

  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
    await _scheduleDeadManCheck();
  }

  Future<void> _scheduleDeadManCheck() async {
    await Workmanager().registerPeriodicTask(
      _deadManTaskName,
      _deadManTaskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  Future<void> updateCheckIn() async {
    await SecureEnclaveStorage.instance.saveLastCheckIn();
  }

  Future<void> setDeadManHours(int hours) async {
    await SecureEnclaveStorage.instance.saveDeadManHours(hours);
  }

  Future<int> getDeadManHours() async {
    return SecureEnclaveStorage.instance.getDeadManHours();
  }

  Future<void> cancelDeadManSwitch() async {
    await Workmanager().cancelByUniqueName(_deadManTaskName);
    await Workmanager().cancelByUniqueName(_wipeTaskName);
  }

  Future<bool> isDeadManActive() async {
    final lastCheckIn = await SecureEnclaveStorage.instance.getLastCheckIn();
    return lastCheckIn != null;
  }
}
