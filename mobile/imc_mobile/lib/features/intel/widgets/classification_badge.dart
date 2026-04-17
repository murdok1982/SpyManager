import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/colors.dart';
import '../../../models/agent.dart';

class ClassificationBadge extends StatelessWidget {
  const ClassificationBadge({
    super.key,
    required this.level,
    this.large = false,
  });

  final ClassificationLevel level;
  final bool large;

  Color get _color {
    switch (level) {
      case ClassificationLevel.unclassified:
        return AppColors.unclassified;
      case ClassificationLevel.confidential:
        return AppColors.classified;
      case ClassificationLevel.secret:
        return AppColors.secret;
      case ClassificationLevel.topSecret:
        return AppColors.topSecret;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 8,
        vertical: large ? 8 : 3,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withOpacity(0.6)),
      ),
      child: Text(
        level.displayName,
        style: GoogleFonts.robotoMono(
          fontSize: large ? 12 : 9,
          fontWeight: FontWeight.bold,
          color: _color,
          letterSpacing: large ? 2 : 1.5,
        ),
      ),
    );
  }
}
