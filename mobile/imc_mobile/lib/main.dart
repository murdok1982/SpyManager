import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workmanager/workmanager.dart';
import 'app/app.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'core/security/anti_tamper_service.dart';
import 'features/ghost/ghost_mode_service.dart';
import 'features/deadman/dead_man_service.dart';
import 'features/mesh/mesh_service.dart';
import 'features/biometrics/behavioral_biometrics_service.dart';
import 'features/multimodal/multimodal_service.dart';
import 'features/sync/graceful_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0E1A),
  ));

  // Initialize security services
  await _initializeSecurity();

  // Initialize background services
  await DeadManService.instance.initialize();
  await GracefulSyncService.instance.database;

  // Initialize feature services
  GhostModeService.instance.initialize();
  await MeshService.instance.initialize();
  await MultimodalService.instance.initialize();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
      ],
      child: const IMCApp(),
    ),
  );
}

Future<void> _initializeSecurity() async {
  try {
    final result = await AntiTamperService.instance.performSecurityCheck();
    if (!result.isSecure) {
      final agentId = await SecureEnclaveStorage.instance.getAgentId();
      if (agentId != null) {
        await AntiTamperService.instance.handleSecurityBreach(agentId);
      }
    }
  } catch (_) {}
}
