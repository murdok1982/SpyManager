import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/wear_colors.dart';

class LocationBeaconScreen extends StatefulWidget {
  const LocationBeaconScreen({super.key});

  @override
  State<LocationBeaconScreen> createState() => _LocationBeaconScreenState();
}

class _LocationBeaconScreenState extends State<LocationBeaconScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scale;
  // In a real device, this would come from a GPS service.
  // For the wearable prototype, we simulate GPS state.
  final bool _hasSignal = true;
  final DateTime? _lastFix = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WearColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scale,
                child: Icon(
                  _hasSignal ? Icons.gps_fixed : Icons.gps_off,
                  size: 56,
                  color: _hasSignal ? WearColors.cyan : WearColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _hasSignal ? 'TRACKING ACTIVE' : 'NO SIGNAL',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _hasSignal
                      ? WearColors.textPrimary
                      : WearColors.textMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              if (_hasSignal && _lastFix != null)
                Text(
                  'FIX ${DateFormat('HH:mm:ss').format(_lastFix!)} UTC',
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 10,
                    color: WearColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
