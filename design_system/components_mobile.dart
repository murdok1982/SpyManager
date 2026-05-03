import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'tokens.dart';

class GhostModeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const GhostModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Modo Fantasma', style: TextStyle(color: AppTokens.textPrimary)),
      subtitle: const Text('Oculta la app del launcher', style: TextStyle(color: AppTokens.textSecondary)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTokens.ghostGray,
    );
  }
}

class DuressPINPad extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;

  const DuressPINPad({
    super.key,
    required this.controller,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          obscureText: true,
          maxLength: 6,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTokens.textPrimary, fontSize: 24, letterSpacing: 16),
          decoration: InputDecoration(
            counterText: '',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppTokens.alertRed, width: AppTokens.borderWidth),
            ),
            labelText: 'PIN de Coacción',
            labelStyle: TextStyle(color: AppTokens.alertRed),
          ),
          onSubmitted: onCompleted,
        ),
      ],
    );
  }
}

class DeadManSwitchConfig extends StatelessWidget {
  final int hours;
  final bool autoWipe;
  final ValueChanged<int> onHoursChanged;
  final ValueChanged<bool> onAutoWipeChanged;

  const DeadManSwitchConfig({
    super.key,
    required this.hours,
    required this.autoWipe,
    required this.onHoursChanged,
    required this.onAutoWipeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Umbral: $hours h', style: const TextStyle(color: AppTokens.textPrimary)),
        Slider(
          value: hours.toDouble(),
          min: 12,
          max: 168,
          divisions: 13,
          label: '$hours h',
          onChanged: (v) => onHoursChanged(v.round()),
          activeColor: AppTokens.alertRed,
        ),
        SwitchListTile(
          title: const Text('Auto-Wipe', style: TextStyle(color: AppTokens.textPrimary)),
          value: autoWipe,
          onChanged: onAutoWipeChanged,
          activeColor: AppTokens.alertRed,
        ),
      ],
    );
  }
}

class SteganographyUpload extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onEncode;
  final VoidCallback onDecode;
  final TextEditingController messageController;

  const SteganographyUpload({
    super.key,
    required this.onPickImage,
    required this.onEncode,
    required this.onDecode,
    required this.messageController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTokens.secondaryColor,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingM),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: onPickImage,
              icon: const Icon(Icons.image),
              label: const Text('Seleccionar Imagen'),
            ),
            const SizedBox(height: AppTokens.spacingM),
            TextField(
              controller: messageController,
              maxLines: 5,
              style: const TextStyle(color: AppTokens.textPrimary),
              decoration: InputDecoration(
                labelText: 'Mensaje a ocultar',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTokens.accentColor),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingM),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEncode,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTokens.militaryGreen),
                    child: const Text('Codificar'),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingS),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDecode,
                    child: const Text('Decodificar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HoneypotCaseCard extends StatelessWidget {
  final String caseName;
  final VoidCallback onTap;

  const HoneypotCaseCard({
    super.key,
    required this.caseName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTokens.backgroundDark,
      shape: Border.all(color: AppTokens.honeypotYellow, width: AppTokens.borderWidth),
      child: ListTile(
        leading: Icon(Icons.warning, color: AppTokens.honeypotYellow),
        title: Text(caseName, style: TextStyle(color: AppTokens.honeypotYellow, fontWeight: FontWeight.bold)),
        subtitle: const Text('CASO HONEYPOT - ACCESO REGISTRADO', style: TextStyle(color: Colors.red)),
        onTap: onTap,
      ),
    );
  }
}

class BehavioralBiometricsDashboard extends StatelessWidget {
  final double typingSpeed;
  final double anomalyScore;
  final bool isAnomaly;

  const BehavioralBiometricsDashboard({
    super.key,
    required this.typingSpeed,
    required this.anomalyScore,
    required this.isAnomaly,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isAnomaly ? Colors.red[900] : AppTokens.secondaryColor,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Biometría Comportamental', style: TextStyle(color: AppTokens.biometricPurple, fontSize: AppTokens.fontSizeL)),
            const SizedBox(height: AppTokens.spacingS),
            Text('Velocidad: ${typingSpeed.toStringAsFixed(1)} ms', style: const TextStyle(color: AppTokens.textPrimary)),
            Text('Anomalía: ${(anomalyScore * 100).toStringAsFixed(1)}%', style: TextStyle(color: isAnomaly ? Colors.red : AppTokens.textPrimary)),
            if (isAnomaly)
              const Text('¡ANOMALÍA DETECTADA!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
