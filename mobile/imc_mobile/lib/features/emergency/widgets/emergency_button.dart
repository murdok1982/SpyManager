import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/theme/colors.dart';

class EmergencyButton extends StatelessWidget {
  const EmergencyButton({super.key, this.isAlertActive = false});

  final bool isAlertActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        context.push(AppConstants.routeEmergency);
      },
      child: Semantics(
        label: 'Emergency SOS button',
        button: true,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.danger,
            border: Border.all(
              color: isAlertActive
                  ? AppColors.warning
                  : AppColors.danger,
              width: isAlertActive ? 3 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withOpacity(0.5),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.sos_outlined,
            size: 26,
            color: Colors.white,
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
              autoPlay: isAlertActive,
            )
            .scaleXY(
              begin: 0.95,
              end: 1.05,
              duration: 800.ms,
              curve: Curves.easeInOut,
            ),
      ),
    );
  }
}
