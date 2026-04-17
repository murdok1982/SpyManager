import 'agent.dart';

enum IntelReportType { fieldReport, contactLog, evidenceCapture }

class IntelReport {
  const IntelReport({
    required this.id,
    required this.agentId,
    required this.caseId,
    required this.type,
    required this.content,
    required this.classificationLevel,
    required this.createdAt,
    this.reportHash,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String agentId;
  final String caseId;
  final IntelReportType type;
  final String content;
  final ClassificationLevel classificationLevel;
  final DateTime createdAt;
  final String? reportHash;
  final double? latitude;
  final double? longitude;

  factory IntelReport.fromJson(Map<String, dynamic> json) {
    return IntelReport(
      id: json['id'] as String,
      agentId: json['agent_id'] as String,
      caseId: json['case_id'] as String,
      type: IntelReportType.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['type'] as String).toLowerCase(),
        orElse: () => IntelReportType.fieldReport,
      ),
      content: json['content'] as String,
      classificationLevel: ClassificationLevel.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (json['classification_level'] as String).toLowerCase(),
        orElse: () => ClassificationLevel.unclassified,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      reportHash: json['report_hash'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'case_id': caseId,
      'type': type.name,
      'content': content,
      'classification_level': classificationLevel.name,
      'created_at': createdAt.toUtc().toIso8601String(),
      if (reportHash != null) 'report_hash': reportHash,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

class MobileReport {
  const MobileReport({
    required this.agentId,
    required this.caseId,
    required this.type,
    required this.content,
    required this.classificationLevel,
    this.latitude,
    this.longitude,
  });

  final String agentId;
  final String caseId;
  final IntelReportType type;
  final String content;
  final ClassificationLevel classificationLevel;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() {
    return {
      'agent_id': agentId,
      'case_id': caseId,
      'type': type.name,
      'content': content,
      'classification_level': classificationLevel.name,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

extension IntelReportTypeExtension on IntelReportType {
  String get displayName {
    switch (this) {
      case IntelReportType.fieldReport:
        return 'FIELD REPORT';
      case IntelReportType.contactLog:
        return 'CONTACT LOG';
      case IntelReportType.evidenceCapture:
        return 'EVIDENCE CAPTURE';
    }
  }
}
