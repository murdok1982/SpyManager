import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';

class _AuditEntry {
  const _AuditEntry({
    required this.timestamp,
    required this.action,
    required this.agentId,
    required this.hash,
    required this.chainIntact,
  });

  final DateTime timestamp;
  final String action;
  final String agentId;
  final String hash;
  final bool chainIntact;
}

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  static final List<_AuditEntry> _mockEntries = [
    _AuditEntry(
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)).toUtc(),
      action: 'LOGIN — PKI_CERTIFICATE_VERIFIED',
      agentId: 'AGT-001',
      hash: 'A3F2C1D8E4B7',
      chainIntact: true,
    ),
    _AuditEntry(
      timestamp: DateTime.now().subtract(const Duration(minutes: 22)).toUtc(),
      action: 'INTEL_REPORT_SUBMITTED — CASE-ALPHA',
      agentId: 'AGT-001',
      hash: 'B7E4A2F1C9D5',
      chainIntact: true,
    ),
    _AuditEntry(
      timestamp: DateTime.now().subtract(const Duration(hours: 1)).toUtc(),
      action: 'WEARABLE_SYNC — 3 EVENTS PROCESSED',
      agentId: 'AGT-001',
      hash: 'C9D5B3E64A1F',
      chainIntact: true,
    ),
    _AuditEntry(
      timestamp: DateTime.now().subtract(const Duration(hours: 2)).toUtc(),
      action: 'CASE_ACCESS — CASE-BRAVO OPENED',
      agentId: 'AGT-001',
      hash: 'D1F8C2A5E7B3',
      chainIntact: true,
    ),
    _AuditEntry(
      timestamp: DateTime.now().subtract(const Duration(hours: 4)).toUtc(),
      action: 'STATUS_UPDATE — ACTIVE',
      agentId: 'AGT-001',
      hash: 'E6A3D9B1C8F2',
      chainIntact: false,
    ),
    _AuditEntry(
      timestamp: DateTime.now().subtract(const Duration(hours: 6)).toUtc(),
      action: 'LOCATION_BEACON — SECTOR 7',
      agentId: 'AGT-007',
      hash: 'F2B8E5C1D4A9',
      chainIntact: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(
          'AUDIT LOG',
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _allIntact(_mockEntries)
                        ? AppColors.accentGreen
                        : AppColors.danger,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _allIntact(_mockEntries) ? 'CHAIN OK' : 'CHAIN BROKEN',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: _allIntact(_mockEntries)
                        ? AppColors.accentGreen
                        : AppColors.danger,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockEntries.length,
        itemBuilder: (context, index) {
          return _AuditEntryTile(entry: _mockEntries[index]);
        },
      ),
    );
  }

  bool _allIntact(List<_AuditEntry> entries) =>
      entries.every((e) => e.chainIntact);
}

class _AuditEntryTile extends StatelessWidget {
  const _AuditEntryTile({required this.entry});

  final _AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final truncatedHash = entry.hash.length > 8
        ? '${entry.hash.substring(0, 8)}...'
        : entry.hash;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: entry.chainIntact
              ? AppColors.borderSubtle
              : AppColors.danger.withOpacity(0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            entry.chainIntact ? Icons.lock_outline : Icons.lock_open_outlined,
            size: 18,
            color: entry.chainIntact
                ? AppColors.accentGreen
                : AppColors.danger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.action,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      entry.agentId,
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        color: AppColors.accentCyan,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.timestamp),
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Text(' UTC',
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 10,
                          color: AppColors.textMuted,
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.tag,
                      size: 10,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      truncatedHash,
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (!entry.chainIntact) ...[
                      const SizedBox(width: 8),
                      Text(
                        'CHAIN BROKEN',
                        style: GoogleFonts.robotoMono(
                          fontSize: 9,
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
