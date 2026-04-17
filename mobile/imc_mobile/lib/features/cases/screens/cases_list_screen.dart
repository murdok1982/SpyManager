import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/colors.dart';
import '../../../models/agent.dart';
import '../../../models/case_model.dart';
import '../widgets/case_list_item.dart';

class CasesListScreen extends StatefulWidget {
  const CasesListScreen({super.key});

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  ClassificationLevel? _classificationFilter;
  CaseStatus? _statusFilter;

  List<CaseModel> get _filteredCases {
    return CaseModel.mockList.where((c) {
      if (_classificationFilter != null &&
          c.classificationLevel != _classificationFilter) {
        return false;
      }
      if (_statusFilter != null && c.status != _statusFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'ASSIGNED CASES',
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: AppColors.backgroundSecondary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _FilterBar(
            classificationFilter: _classificationFilter,
            statusFilter: _statusFilter,
            onClassificationChanged: (v) =>
                setState(() => _classificationFilter = v),
            onStatusChanged: (v) => setState(() => _statusFilter = v),
          ),
        ),
      ),
      body: _filteredCases.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredCases.length,
              itemBuilder: (context, index) {
                final c = _filteredCases[index];
                return CaseListItem(
                  caseModel: c,
                  onTap: () => context.push('/cases/${c.id}'),
                );
              },
            ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.classificationFilter,
    required this.statusFilter,
    required this.onClassificationChanged,
    required this.onStatusChanged,
  });

  final ClassificationLevel? classificationFilter;
  final CaseStatus? statusFilter;
  final ValueChanged<ClassificationLevel?> onClassificationChanged;
  final ValueChanged<CaseStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.backgroundSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'FILTER:',
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'ALL',
                    selected: classificationFilter == null && statusFilter == null,
                    onSelected: (_) {
                      onClassificationChanged(null);
                      onStatusChanged(null);
                    },
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'TS',
                    selected: classificationFilter ==
                        ClassificationLevel.topSecret,
                    onSelected: (_) => onClassificationChanged(
                      classificationFilter == ClassificationLevel.topSecret
                          ? null
                          : ClassificationLevel.topSecret,
                    ),
                    color: AppColors.topSecret,
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'SECRET',
                    selected:
                        classificationFilter == ClassificationLevel.secret,
                    onSelected: (_) => onClassificationChanged(
                      classificationFilter == ClassificationLevel.secret
                          ? null
                          : ClassificationLevel.secret,
                    ),
                    color: AppColors.secret,
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'ACTIVE',
                    selected: statusFilter == CaseStatus.active,
                    onSelected: (_) => onStatusChanged(
                      statusFilter == CaseStatus.active
                          ? null
                          : CaseStatus.active,
                    ),
                    color: AppColors.accentGreen,
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: 'OPEN',
                    selected: statusFilter == CaseStatus.open,
                    onSelected: (_) => onStatusChanged(
                      statusFilter == CaseStatus.open ? null : CaseStatus.open,
                    ),
                    color: AppColors.accentCyan,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.textSecondary;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.robotoMono(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: selected ? chipColor : AppColors.textMuted,
          letterSpacing: 1,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: AppColors.backgroundElevated,
      selectedColor: chipColor.withOpacity(0.15),
      side: BorderSide(
        color: selected ? chipColor.withOpacity(0.6) : AppColors.borderSubtle,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_off_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'NO CASES MATCH FILTER',
            style: GoogleFonts.robotoMono(
              fontSize: 13,
              color: AppColors.textMuted,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
