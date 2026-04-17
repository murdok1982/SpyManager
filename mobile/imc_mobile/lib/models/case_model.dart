import 'agent.dart';

enum CaseStatus { open, active, closed, archived }

class CaseModel {
  const CaseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.classificationLevel,
    required this.createdAt,
    required this.assignedAgentIds,
    this.intelReportIds = const [],
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final CaseStatus status;
  final ClassificationLevel classificationLevel;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> assignedAgentIds;
  final List<String> intelReportIds;

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: CaseStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['status'] as String).toLowerCase(),
        orElse: () => CaseStatus.active,
      ),
      classificationLevel: ClassificationLevel.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (json['classification_level'] as String).toLowerCase(),
        orElse: () => ClassificationLevel.unclassified,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      assignedAgentIds: List<String>.from(json['assigned_agent_ids'] as List),
      intelReportIds: json['intel_report_ids'] != null
          ? List<String>.from(json['intel_report_ids'] as List)
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.name,
      'classification_level': classificationLevel.name,
      'created_at': createdAt.toUtc().toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
      'assigned_agent_ids': assignedAgentIds,
      'intel_report_ids': intelReportIds,
    };
  }

  static List<CaseModel> get mockList => [
        CaseModel(
          id: 'CASE-ALPHA',
          title: 'Operation Nightfall',
          description: 'Surveillance of high-value target in sector 7. Coordinate with local assets.',
          status: CaseStatus.active,
          classificationLevel: ClassificationLevel.topSecret,
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
          assignedAgentIds: const ['AGT-001'],
          intelReportIds: const ['RPT-001', 'RPT-002'],
        ),
        CaseModel(
          id: 'CASE-BRAVO',
          title: 'Asset Extraction',
          description: 'Extract compromised asset from hostile territory. Time-sensitive.',
          status: CaseStatus.active,
          classificationLevel: ClassificationLevel.secret,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          assignedAgentIds: const ['AGT-001', 'AGT-007'],
        ),
        CaseModel(
          id: 'CASE-CHARLIE',
          title: 'Communications Intercept',
          description: 'Monitor encrypted communications channel. Log all traffic patterns.',
          status: CaseStatus.open,
          classificationLevel: ClassificationLevel.confidential,
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          assignedAgentIds: const ['AGT-001'],
        ),
      ];
}
