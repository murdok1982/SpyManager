enum AgentStatus { active, dark, standby, compromised }

enum ClassificationLevel { unclassified, confidential, secret, topSecret }

class Agent {
  const Agent({
    required this.id,
    required this.callSign,
    required this.status,
    required this.classificationLevel,
    required this.assignedCaseIds,
    this.avatarUrl,
  });

  final String id;
  final String callSign;
  final AgentStatus status;
  final ClassificationLevel classificationLevel;
  final List<String> assignedCaseIds;
  final String? avatarUrl;

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      callSign: json['call_sign'] as String,
      status: AgentStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['status'] as String).toLowerCase(),
        orElse: () => AgentStatus.standby,
      ),
      classificationLevel: ClassificationLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['classification_level'] as String).toLowerCase(),
        orElse: () => ClassificationLevel.unclassified,
      ),
      assignedCaseIds: List<String>.from(json['assigned_case_ids'] as List),
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'call_sign': callSign,
      'status': status.name,
      'classification_level': classificationLevel.name,
      'assigned_case_ids': assignedCaseIds,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }

  /// Mock agent for development
  static Agent get mock => const Agent(
        id: 'AGT-001',
        callSign: 'PHANTOM',
        status: AgentStatus.active,
        classificationLevel: ClassificationLevel.secret,
        assignedCaseIds: ['CASE-ALPHA', 'CASE-BRAVO'],
      );
}

extension AgentStatusExtension on AgentStatus {
  String get displayName {
    switch (this) {
      case AgentStatus.active:
        return 'ACTIVE';
      case AgentStatus.dark:
        return 'DARK';
      case AgentStatus.standby:
        return 'STANDBY';
      case AgentStatus.compromised:
        return 'COMPROMISED';
    }
  }
}

extension ClassificationLevelExtension on ClassificationLevel {
  String get displayName {
    switch (this) {
      case ClassificationLevel.unclassified:
        return 'UNCLASSIFIED';
      case ClassificationLevel.confidential:
        return 'CONFIDENTIAL';
      case ClassificationLevel.secret:
        return 'SECRET';
      case ClassificationLevel.topSecret:
        return 'TOP SECRET';
    }
  }
}
