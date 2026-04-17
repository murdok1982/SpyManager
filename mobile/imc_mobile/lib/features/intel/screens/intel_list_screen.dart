import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme/colors.dart';
import '../../../models/intel_report.dart';
import '../../../models/agent.dart';
import '../widgets/encrypted_message_bubble.dart';

class IntelListScreen extends StatelessWidget {
  const IntelListScreen({super.key});

  static List<IntelReport> get _mockReports => [
        IntelReport(
          id: 'RPT-001',
          agentId: 'AGT-001',
          caseId: 'CASE-ALPHA',
          type: IntelReportType.fieldReport,
          content:
              'Target observed leaving secure facility at 14:32 UTC. Vehicle: dark sedan, partial plate '
              'XJ-7. Proceeded north on Boulevard Sector 7. Contact established with unknown associate.',
          classificationLevel: ClassificationLevel.topSecret,
          createdAt:
              DateTime.now().subtract(const Duration(hours: 2)).toUtc(),
          reportHash: 'A3F2C1D8',
        ),
        IntelReport(
          id: 'RPT-002',
          agentId: 'AGT-001',
          caseId: 'CASE-ALPHA',
          type: IntelReportType.contactLog,
          content:
              'Asset ECHO confirmed dead drop retrieval at grid reference 47.3N 12.1E. Package intact. '
              'Counter-surveillance negative.',
          classificationLevel: ClassificationLevel.secret,
          createdAt:
              DateTime.now().subtract(const Duration(hours: 8)).toUtc(),
          reportHash: 'B7E4A2F1',
        ),
        IntelReport(
          id: 'RPT-003',
          agentId: 'AGT-007',
          caseId: 'CASE-BRAVO',
          type: IntelReportType.evidenceCapture,
          content:
              'Photographic evidence of illicit communications equipment in warehouse district. '
              'Coordinates attached. Request forensic team deployment.',
          classificationLevel: ClassificationLevel.secret,
          createdAt:
              DateTime.now().subtract(const Duration(days: 1)).toUtc(),
          reportHash: 'C9D5B3E6',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(
          'INTEL REPORTS',
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined, size: 20),
            color: AppColors.textSecondary,
            onPressed: () {},
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _mockReports.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _mockReports.length,
              itemBuilder: (context, index) {
                final report = _mockReports[index];
                return _ReportItem(report: report);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppConstants.routeIntelReport),
        backgroundColor: AppColors.accentCyan,
        foregroundColor: AppColors.backgroundPrimary,
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'NEW REPORT',
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        tooltip: 'Submit new intel report',
      ),
    );
  }
}

class _ReportItem extends StatelessWidget {
  const _ReportItem({required this.report});

  final IntelReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportHeader(report: report),
          const SizedBox(height: 6),
          EncryptedMessageBubble(
            content: report.content,
            hash: report.reportHash ?? 'UNVERIFIED',
            timestamp: report.createdAt,
          ),
        ],
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.report});

  final IntelReport report;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          color: _typeColor(report.type),
        ),
        const SizedBox(width: 8),
        Text(
          report.id,
          style: GoogleFonts.robotoMono(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _typeColor(report.type).withOpacity(0.12),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: _typeColor(report.type).withOpacity(0.4),
            ),
          ),
          child: Text(
            report.type.displayName,
            style: GoogleFonts.robotoMono(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: _typeColor(report.type),
              letterSpacing: 1,
            ),
          ),
        ),
        const Spacer(),
        Text(
          DateFormat('HH:mm').format(report.createdAt),
          style: GoogleFonts.robotoMono(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Color _typeColor(IntelReportType type) {
    switch (type) {
      case IntelReportType.fieldReport:
        return AppColors.accentCyan;
      case IntelReportType.contactLog:
        return AppColors.accentGreen;
      case IntelReportType.evidenceCapture:
        return AppColors.warning;
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'NO INTEL REPORTS',
            style: GoogleFonts.robotoMono(
              fontSize: 13,
              color: AppColors.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Submit your first field report',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
