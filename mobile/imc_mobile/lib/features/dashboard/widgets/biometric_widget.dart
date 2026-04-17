import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/colors.dart';
import '../../../models/wearable_event.dart';

class BiometricWidget extends StatelessWidget {
  const BiometricWidget({
    super.key,
    required this.biometrics,
    required this.isConnected,
  });

  final WearableBiometrics? biometrics;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite_outline,
                size: 16,
                color: isConnected ? AppColors.accentGreen : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'BIOMETRICS',
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.accentGreen.withOpacity(0.1)
                      : AppColors.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isConnected
                        ? AppColors.accentGreen.withOpacity(0.4)
                        : AppColors.textMuted.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isConnected ? 'WEARABLE LINKED' : 'NO DEVICE',
                  style: GoogleFonts.robotoMono(
                    fontSize: 9,
                    color: isConnected ? AppColors.accentGreen : AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (biometrics != null)
            _BiometricReadings(biometrics: biometrics!)
          else
            _NoBiometricData(),
        ],
      ),
    );
  }
}

class _BiometricReadings extends StatelessWidget {
  const _BiometricReadings({required this.biometrics});

  final WearableBiometrics biometrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'HEART RATE',
            value: '${biometrics.heartRate}',
            unit: 'BPM',
            color: _hrColor(biometrics.heartRate),
            icon: Icons.favorite,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            label: 'STRESS',
            value: '${biometrics.stressLevel}',
            unit: '/100',
            color: _stressColor(biometrics.stressLevel),
            icon: Icons.psychology_outlined,
          ),
        ),
        if (biometrics.temperature != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _MetricTile(
              label: 'TEMP',
              value: biometrics.temperature!.toStringAsFixed(1),
              unit: '°C',
              color: AppColors.accentCyan,
              icon: Icons.thermostat_outlined,
            ),
          ),
        ],
      ],
    );
  }

  Color _hrColor(int hr) {
    if (hr < 60 || hr > 120) return AppColors.danger;
    if (hr > 100) return AppColors.warning;
    return AppColors.safe;
  }

  Color _stressColor(int stress) {
    if (stress >= 80) return AppColors.danger;
    if (stress >= 60) return AppColors.warning;
    return AppColors.safe;
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.robotoMono(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                unit,
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  color: color.withOpacity(0.7),
                ),
              ),
            ],
          ),
          Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: 9,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoBiometricData extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.bluetooth_disabled,
          size: 20,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Text(
          'CONNECT WEARABLE TO SEE BIOMETRICS',
          style: GoogleFonts.robotoMono(
            fontSize: 11,
            color: AppColors.textMuted,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
