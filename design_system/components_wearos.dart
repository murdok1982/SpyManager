import 'package:flutter/material.dart';
import 'package:wear/wear.dart';
import 'tokens.dart';

class MeshStatusWidget extends StatelessWidget {
  final bool isConnected;
  final int signalStrength;

  const MeshStatusWidget({
    super.key,
    required this.isConnected,
    this.signalStrength = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.watchPadding),
      decoration: BoxDecoration(
        color: isConnected ? AppTokens.meshBlue : Colors.grey,
        borderRadius: BorderRadius.circular(AppTokens.watchBorderRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'MESH:$signalStrength' : 'OFF',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class CovertChannelToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const CovertChannelToggle({
    super.key,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(Icons.lock, color: enabled ? AppTokens.covertGreen : Colors.grey, size: 16),
        Switch(
          value: enabled,
          onChanged: onChanged,
          activeColor: AppTokens.covertGreen,
        ),
      ],
    );
  }
}

class DeadManSwitchWearable extends StatelessWidget {
  final bool isActive;
  final int hoursRemaining;
  final VoidCallback onCheckin;

  const DeadManSwitchWearable({
    super.key,
    required this.isActive,
    this.hoursRemaining = 0,
    required this.onCheckin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.watchPadding),
      decoration: BoxDecoration(
        color: isActive ? AppTokens.alertRed.withOpacity(0.3) : Colors.grey[800],
        borderRadius: BorderRadius.circular(AppTokens.watchBorderRadius),
      ),
      child: Column(
        children: [
          Text(
            isActive ? 'DMS: $hoursRemaining h' : 'DMS: OFF',
            style: TextStyle(
              color: isActive ? AppTokens.alertRed : Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: onCheckin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.militaryGreen,
              minimumSize: const Size(60, 24),
            ),
            child: const Text('CHECK', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class SteganographyQuickEncode extends StatelessWidget {
  final VoidCallback onEncode;

  const SteganographyQuickEncode({
    super.key,
    required this.onEncode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEncode,
      child: Container(
        padding: const EdgeInsets.all(AppTokens.watchPadding),
        decoration: BoxDecoration(
          color: AppTokens.accentColor,
          borderRadius: BorderRadius.circular(AppTokens.watchBorderRadius),
        ),
        child: const Column(
          children: [
            Icon(Icons.image, color: Colors.white, size: 24),
            Text('STEG', style: TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class BehavioralBiometricsWearable extends StatelessWidget {
  final double typingMetric;

  const BehavioralBiometricsWearable({
    super.key,
    required this.typingMetric,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.watchPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('BIO', style: TextStyle(color: AppTokens.biometricPurple, fontSize: 10)),
          Text(
            typingMetric.toStringAsFixed(0),
            style: const TextStyle(color: AppTokens.textPrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class GhostModeIndicator extends StatelessWidget {
  final bool isGhostMode;

  const GhostModeIndicator({
    super.key,
    required this.isGhostMode,
  });

  @override
  Widget build(BuildContext context) {
    if (!isGhostMode) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTokens.ghostGray,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('GHOST', style: TextStyle(color: Colors.white, fontSize: 8)),
    );
  }
}
