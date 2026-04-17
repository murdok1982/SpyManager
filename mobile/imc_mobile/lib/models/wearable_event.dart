enum WearableEventType {
  heartRate,
  stressLevel,
  temperature,
  emergencySos,
  quickReport,
  locationPing,
  statusUpdate,
}

class WearableEvent {
  const WearableEvent({
    required this.agentId,
    required this.type,
    required this.timestamp,
    this.heartRate,
    this.stressLevel,
    this.temperature,
    this.latitude,
    this.longitude,
    this.payload,
  });

  final String agentId;
  final WearableEventType type;
  final DateTime timestamp;
  final int? heartRate;
  final int? stressLevel;
  final double? temperature;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? payload;

  factory WearableEvent.fromJson(Map<String, dynamic> json) {
    return WearableEvent(
      agentId: json['agent_id'] as String,
      type: WearableEventType.values.firstWhere(
        (e) => e.name.toLowerCase() == (json['type'] as String).toLowerCase(),
        orElse: () => WearableEventType.statusUpdate,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      heartRate: json['heart_rate'] as int?,
      stressLevel: json['stress_level'] as int?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agent_id': agentId,
      'type': type.name,
      'timestamp': timestamp.toUtc().toIso8601String(),
      if (heartRate != null) 'heart_rate': heartRate,
      if (stressLevel != null) 'stress_level': stressLevel,
      if (temperature != null) 'temperature': temperature,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (payload != null) 'payload': payload,
    };
  }

  /// Mock wearable data for development
  static WearableEvent get mockHeartRate => WearableEvent(
        agentId: 'AGT-001',
        type: WearableEventType.heartRate,
        timestamp: DateTime.now().toUtc(),
        heartRate: 72,
        stressLevel: 34,
        temperature: 36.7,
      );
}

class WearableBiometrics {
  const WearableBiometrics({
    required this.heartRate,
    required this.stressLevel,
    this.temperature,
    this.updatedAt,
  });

  final int heartRate;
  final int stressLevel;
  final double? temperature;
  final DateTime? updatedAt;

  static WearableBiometrics get mock => WearableBiometrics(
        heartRate: 72,
        stressLevel: 34,
        temperature: 36.7,
        updatedAt: DateTime.now().toUtc(),
      );

  String get stressLabel {
    if (stressLevel < 30) return 'LOW';
    if (stressLevel < 60) return 'MODERATE';
    if (stressLevel < 80) return 'HIGH';
    return 'CRITICAL';
  }
}
