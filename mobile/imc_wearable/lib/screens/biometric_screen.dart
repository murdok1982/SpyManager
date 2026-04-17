import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/theme/wear_colors.dart';
import '../core/channel/phone_channel.dart';
import '../services/wear_data_service.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({
    super.key,
    required this.dataService,
    required this.phoneChannel,
  });

  final WearDataService dataService;
  final PhoneChannel phoneChannel;

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  DateTime? _lastUpdate;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    _startAccelerometer();
  }

  void _startAccelerometer() {
    _accelSub = accelerometerEventStream().listen((event) {
      // Simple stress estimation from accelerometer variance
      final magnitude =
          (event.x * event.x + event.y * event.y + event.z * event.z);
      final estimatedStress = ((magnitude - 100).abs() / 2).clamp(0, 100).toInt();

      widget.dataService.updateBiometrics(stress: estimatedStress);
      setState(() => _lastUpdate = DateTime.now().toUtc());

      // Send biometric update to phone
      widget.phoneChannel.sendBiometricUpdate({
        'stress_level': estimatedStress,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  Color _stressColor(int level) {
    if (level < 40) return WearColors.green;
    if (level < 70) return WearColors.amber;
    return WearColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WearColors.bgBase,
      body: ListenableBuilder(
        listenable: widget.dataService,
        builder: (context, _) {
          final hr = widget.dataService.heartRate;
          final stress = widget.dataService.stressLevel;
          final stressColor = _stressColor(stress);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'BIOMETRICS',
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 11,
                      color: WearColors.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 24,
                        color: WearColors.danger,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hr != null ? '$hr BPM' : '-- BPM',
                        style: const TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: WearColors.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'STRESS',
                            style: TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 10,
                              color: WearColors.textSecondary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            '$stress%',
                            style: TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: stressColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stress / 100.0,
                          minHeight: 10,
                          backgroundColor: WearColors.bgSurface,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(stressColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_lastUpdate != null)
                    Text(
                      'UPDATED ${DateFormat('HH:mm:ss').format(_lastUpdate!)}',
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 9,
                        color: WearColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
