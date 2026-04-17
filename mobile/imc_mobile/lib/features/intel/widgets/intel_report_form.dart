import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/colors.dart';
import '../../../core/utils/encryption_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../models/agent.dart';
import '../../../models/case_model.dart';
import '../../../models/intel_report.dart';
import '../../../services/imc_api_service.dart';
import 'classification_badge.dart';

class IntelReportForm extends StatefulWidget {
  const IntelReportForm({super.key, this.preselectedCaseId});

  final String? preselectedCaseId;

  @override
  State<IntelReportForm> createState() => _IntelReportFormState();
}

class _IntelReportFormState extends State<IntelReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();

  IntelReportType _selectedType = IntelReportType.fieldReport;
  ClassificationLevel _selectedClassification = ClassificationLevel.secret;
  String? _selectedCaseId;
  bool _submitting = false;
  bool _encrypting = false;
  String? _submittedHash;

  @override
  void initState() {
    super.initState();
    _selectedCaseId = widget.preselectedCaseId ?? CaseModel.mockList.first.id;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedHash != null) {
      return _SuccessView(hash: _submittedHash!);
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: 'REPORT TYPE'),
          const SizedBox(height: 8),
          _TypeSelector(
            selected: _selectedType,
            onChanged: (v) => setState(() => _selectedType = v),
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'ASSIGN TO CASE'),
          const SizedBox(height: 8),
          _CaseDropdown(
            selectedId: _selectedCaseId,
            onChanged: (v) => setState(() => _selectedCaseId = v),
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'CLASSIFICATION LEVEL'),
          const SizedBox(height: 8),
          _ClassificationSelector(
            selected: _selectedClassification,
            onChanged: (v) => setState(() => _selectedClassification = v),
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'INTEL CONTENT'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contentController,
            enabled: !_submitting,
            maxLines: 8,
            style: GoogleFonts.roboto(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              hintText: 'Enter field intelligence, contact details, or evidence description...',
              alignLabelWithHint: true,
            ),
            validator: Validators.validateIntelContent,
          ),
          const SizedBox(height: 24),
          if (_encrypting) _EncryptingIndicator(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_submitting || _encrypting) ? null : _handleSubmit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.backgroundPrimary,
                      ),
                    )
                  : Text(
                      'SUBMIT INTEL REPORT',
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCaseId == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _encrypting = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    setState(() {
      _encrypting = false;
      _submitting = true;
    });

    try {
      final report = MobileReport(
        agentId: 'AGT-001',
        caseId: _selectedCaseId!,
        type: _selectedType,
        content: _contentController.text.trim(),
        classificationLevel: _selectedClassification,
      );

      await IMCApiService.instance.submitIntelReport(report);

      final hash = EncryptionUtils.generateReportHash(
        _contentController.text,
        'AGT-001',
        DateTime.now(),
      );

      HapticFeedback.heavyImpact();
      setState(() {
        _submittedHash = hash;
        _submitting = false;
      });
    } catch (_) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'TRANSMISSION FAILED — CHECK CONNECTION',
            style: GoogleFonts.robotoMono(color: AppColors.danger),
          ),
          backgroundColor: AppColors.backgroundCard,
        ),
      );
    }
  }
}

class _EncryptingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentCyan.withOpacity(0.05),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentCyan,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'ENCRYPTING...',
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color: AppColors.accentCyan,
              letterSpacing: 2,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 300.ms)
              .then()
              .fadeOut(duration: 300.ms),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.robotoMono(
        fontSize: 11,
        color: AppColors.textSecondary,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final IntelReportType selected;
  final ValueChanged<IntelReportType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: IntelReportType.values.map((type) {
        final isSelected = type == selected;
        return ChoiceChip(
          label: Text(
            type.displayName,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              color: isSelected ? AppColors.backgroundPrimary : AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(type),
          selectedColor: AppColors.accentCyan,
          backgroundColor: AppColors.backgroundElevated,
          side: BorderSide(
            color: isSelected ? AppColors.accentCyan : AppColors.borderSubtle,
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}

class _CaseDropdown extends StatelessWidget {
  const _CaseDropdown({
    required this.selectedId,
    required this.onChanged,
  });

  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      style: GoogleFonts.robotoMono(
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      dropdownColor: AppColors.backgroundElevated,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.folder_outlined, size: 18),
      ),
      items: CaseModel.mockList
          .map(
            (c) => DropdownMenuItem<String>(
              value: c.id,
              child: Text('${c.id} — ${c.title}'),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _ClassificationSelector extends StatelessWidget {
  const _ClassificationSelector({
    required this.selected,
    required this.onChanged,
  });

  final ClassificationLevel selected;
  final ValueChanged<ClassificationLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: ClassificationLevel.values.map((level) {
        return GestureDetector(
          onTap: () => onChanged(level),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: level == selected
                  ? _color(level).withOpacity(0.2)
                  : AppColors.backgroundElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: level == selected
                    ? _color(level).withOpacity(0.7)
                    : AppColors.borderSubtle,
                width: level == selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              level.displayName,
              style: GoogleFonts.robotoMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: level == selected ? _color(level) : AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      }).toList(),
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

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.hash});

  final String hash;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen.withOpacity(0.1),
              border: Border.all(color: AppColors.accentGreen, width: 2),
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.accentGreen,
              size: 32,
            ),
          ).animate().scale(begin: const Offset(0, 0)),
          const SizedBox(height: 20),
          Text(
            'INTEL TRANSMITTED',
            style: GoogleFonts.robotoMono(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.accentGreen,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'REPORT HASH',
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              color: AppColors.textMuted,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              hash,
              style: GoogleFonts.robotoMono(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.accentCyan,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'KEEP THIS HASH FOR VERIFICATION',
            style: GoogleFonts.robotoMono(
              fontSize: 9,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'RETURN TO DASHBOARD',
              style: GoogleFonts.robotoMono(
                color: AppColors.accentCyan,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
