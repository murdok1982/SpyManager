import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../models/agent.dart';
import '../../../models/case_model.dart';

class CaseListItem extends StatelessWidget {
  const CaseListItem({
    super.key,
    required this.caseModel,
    required this.onTap,
  });

  final CaseModel caseModel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _classificationColor(caseModel.classificationLevel)
                  .withOpacity(0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      caseModel.id,
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  _CaseClassificationBadge(level: caseModel.classificationLevel),
                  const SizedBox(width: 8),
                  _CaseStatusBadge(status: caseModel.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                caseModel.title,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caseModel.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.folder_outlined,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${caseModel.intelReportIds.length} REPORTS',
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(caseModel.createdAt),
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _classificationColor(ClassificationLevel level) {
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
}

class _CaseClassificationBadge extends StatelessWidget {
  const _CaseClassificationBadge({required this.level});

  final ClassificationLevel level;

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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Text(
        level.displayName,
        style: GoogleFonts.robotoMono(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: _color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _CaseStatusBadge extends StatelessWidget {
  const _CaseStatusBadge({required this.status});

  final CaseStatus status;

  Color get _color {
    switch (status) {
      case CaseStatus.open:
        return AppColors.accentCyan;
      case CaseStatus.active:
        return AppColors.accentGreen;
      case CaseStatus.closed:
        return AppColors.textMuted;
      case CaseStatus.archived:
        return AppColors.textMuted;
    }
  }

  String get _label {
    return status.name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: GoogleFonts.robotoMono(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: _color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
