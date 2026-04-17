import 'package:flutter/material.dart';
import '../core/theme/wear_colors.dart';
import '../services/wear_data_service.dart';

class BiometricDisplay extends StatelessWidget {
  const BiometricDisplay({super.key, required this.dataService});

  final WearDataService dataService;

  Color _stressColor(int level) {
    if (level < 40) return WearColors.green;
    if (level < 70) return WearColors.amber;
    return WearColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dataService,
      builder: (context, _) {
        final hr = dataService.heartRate;
        final stress = dataService.stressLevel;
        final stressColor = _stressColor(stress);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite,
                  size: 16,
                  color: WearColors.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  hr != null ? '$hr BPM' : '-- BPM',
                  style: const TextStyle(
                    fontFamily: 'RobotoMono',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: WearColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: stress / 100.0,
                minHeight: 6,
                backgroundColor: WearColors.bgSurface,
                valueColor: AlwaysStoppedAnimation<Color>(stressColor),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'STRESS ${stress}%',
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 10,
                color: stressColor,
                letterSpacing: 1,
              ),
            ),
          ],
        );
      },
    );
  }
}
