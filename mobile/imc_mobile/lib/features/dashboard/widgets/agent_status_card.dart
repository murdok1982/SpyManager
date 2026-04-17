import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../models/agent.dart';

class AgentStatusCard extends StatelessWidget {
  const AgentStatusCard({
    super.key,
    required this.agent,
  });

  final Agent agent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _statusColor(agent.status).withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _StatusIndicator(status: agent.status),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      agent.callSign,
                      style: GoogleFonts.robotoMono(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    _ClassificationBadge(
                      level: agent.classificationLevel,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(agent.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _statusColor(agent.status).withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        agent.status.displayName,
                        style: GoogleFonts.robotoMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _statusColor(agent.status),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ID: ${agent.id}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'CASES: ${agent.assignedCaseIds.length} ACTIVE',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(AgentStatus status) {
    switch (status) {
      case AgentStatus.active:
        return AppColors.accentCyan;
      case AgentStatus.dark:
        return AppColors.textMuted;
      case AgentStatus.standby:
        return AppColors.warning;
      case AgentStatus.compromised:
        return AppColors.danger;
    }
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status});

  final AgentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    final shouldPulse = status == AgentStatus.active ||
        status == AgentStatus.compromised;

    Widget dot = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );

    if (shouldPulse) {
      dot = dot
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.2, 1.2),
            duration: 1200.ms,
            curve: Curves.easeInOut,
          );
    }

    return dot;
  }

  Color _color(AgentStatus status) {
    switch (status) {
      case AgentStatus.active:
        return AppColors.accentCyan;
      case AgentStatus.dark:
        return AppColors.textMuted;
      case AgentStatus.standby:
        return AppColors.warning;
      case AgentStatus.compromised:
        return AppColors.danger;
    }
  }
}

class _ClassificationBadge extends StatelessWidget {
  const _ClassificationBadge({required this.level});

  final ClassificationLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color(level).withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: _color(level).withOpacity(0.5)),
      ),
      child: Text(
        level.displayName,
        style: GoogleFonts.robotoMono(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: _color(level),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Color _color(ClassificationLevel level) {
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
