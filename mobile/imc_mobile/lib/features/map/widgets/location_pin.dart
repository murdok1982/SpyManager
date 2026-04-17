import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

enum LocationPinVariant { current, intel, deadDrop }

class LocationPin extends StatelessWidget {
  const LocationPin({
    super.key,
    required this.variant,
    this.label,
  });

  final LocationPinVariant variant;
  final String? label;

  Color get _color {
    switch (variant) {
      case LocationPinVariant.current:
        return AppColors.accentCyan;
      case LocationPinVariant.intel:
        return AppColors.warning;
      case LocationPinVariant.deadDrop:
        return AppColors.danger;
    }
  }

  IconData get _icon {
    switch (variant) {
      case LocationPinVariant.current:
        return Icons.my_location;
      case LocationPinVariant.intel:
        return Icons.push_pin;
      case LocationPinVariant.deadDrop:
        return Icons.warning_amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color.withOpacity(0.2),
            border: Border.all(color: _color, width: 2),
            boxShadow: [
              BoxShadow(
                color: _color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(_icon, color: _color, size: 18),
        ),
        Container(
          width: 2,
          height: 10,
          color: _color,
        ),
        if (label != null) ...[
          const SizedBox(height: 2),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _color.withOpacity(0.5)),
            ),
            child: Text(
              label!,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 9,
                color: _color,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
