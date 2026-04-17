import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme/colors.dart';
import '../../../models/agent.dart';
import '../../../models/case_model.dart';

class CaseDetailScreen extends StatelessWidget {
  const CaseDetailScreen({
    super.key,
    required this.caseId,
  });

  final String caseId;

  @override
  Widget build(BuildContext context) {
    final caseModel = CaseModel.mockList.firstWhere(
      (c) => c.id == caseId,
      orElse: () => CaseModel.mockList.first,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(
          caseModel.id,
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.accentCyan,
            letterSpacing: 2,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppConstants.routeIntelReport),
            icon: const Icon(Icons.add, size: 16, color: AppColors.accentCyan),
            label: Text(
              'ADD INTEL',
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                color: AppColors.accentCyan,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CaseHeader(caseModel: caseModel),
            const SizedBox(height: 20),
            _SectionLabel(label: 'DESCRIPTION'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                caseModel.description,
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(
                label: 'INTEL REPORTS (${caseModel.intelReportIds.length})'),
            const SizedBox(height: 8),
            if (caseModel.intelReportIds.isEmpty)
              _NoIntelMessage()
            else
              ...caseModel.intelReportIds
                  .map((id) => _IntelReportTile(reportId: id))
                  .toList(),
          ],
        ),
      ),
    );
  }
}

class _CaseHeader extends StatelessWidget {
  const _CaseHeader({required this.caseModel});

  final CaseModel caseModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _classificationColor(caseModel.classificationLevel)
              .withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  caseModel.title,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _ClassBadge(level: caseModel.classificationLevel),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),
          _MetaRow(
            label: 'STATUS',
            value: caseModel.status.name.toUpperCase(),
            valueColor: _statusColor(caseModel.status),
          ),
          const SizedBox(height: 6),
          _MetaRow(
            label: 'CREATED',
            value: DateFormat('yyyy-MM-dd HH:mm').format(caseModel.createdAt),
          ),
          const SizedBox(height: 6),
          _MetaRow(
            label: 'AGENTS',
            value: caseModel.assignedAgentIds.join(', '),
          ),
        ],
      ),
    );
  }

  Color _classificationColor(ClassificationLevel level) {
    switch (level) {
      case ClassificationLevel.topSecret:
        return AppColors.topSecret;
      case ClassificationLevel.secret:
        return AppColors.secret;
      case ClassificationLevel.confidential:
        return AppColors.classified;
      case ClassificationLevel.unclassified:
        return AppColors.unclassified;
    }
  }

  Color _statusColor(CaseStatus status) {
    switch (status) {
      case CaseStatus.active:
        return AppColors.accentGreen;
      case CaseStatus.open:
        return AppColors.accentCyan;
      case CaseStatus.closed:
        return AppColors.textMuted;
      case CaseStatus.archived:
        return AppColors.textMuted;
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ClassBadge extends StatelessWidget {
  const _ClassBadge({required this.level});

  final ClassificationLevel level;

  Color get _color {
    switch (level) {
      case ClassificationLevel.topSecret:
        return AppColors.topSecret;
      case ClassificationLevel.secret:
        return AppColors.secret;
      case ClassificationLevel.confidential:
        return AppColors.classified;
      case ClassificationLevel.unclassified:
        return AppColors.unclassified;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Text(
        level.displayName,
        style: GoogleFonts.robotoMono(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppColors.accentCyan),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.robotoMono(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _IntelReportTile extends StatelessWidget {
  const _IntelReportTile({required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 16, color: AppColors.accentCyan),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reportId,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'FIELD REPORT — ENCRYPTED',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _NoIntelMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Center(
        child: Text(
          'NO INTEL REPORTS YET',
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            color: AppColors.textMuted,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
