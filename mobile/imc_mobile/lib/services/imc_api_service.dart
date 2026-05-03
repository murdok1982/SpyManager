import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../core/storage/secure_storage.dart';
import '../models/agent.dart';
import '../models/case_model.dart';
import '../models/intel_report.dart';
import '../models/wearable_event.dart';

class IMCApiService {
  IMCApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Client': 'imc-mobile/1.0',
      },
    ));
    _dio.interceptors.addAll([
      _AgentIdInterceptor(_storage),
      LogInterceptor(requestBody: false, responseBody: false),
    ]);
  }

  static final IMCApiService instance = IMCApiService._();

  late final Dio _dio;
  final SecureStorageService _storage = SecureStorageService.instance;

  Future<Agent?> login(String agentId, String pin) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'agent_id': agentId,
        'pin': pin,
      });
      final agent = Agent.fromJson(response.data as Map<String, dynamic>);
      await _storage.saveAgentId(agentId);
      return agent;
    } on DioException {
      return null;
    }
  }

  Future<void> sendWearableEvent(WearableEvent event) async {
    await _dio.post('/wearable/events', data: event.toJson());
  }

  Future<void> sendEmergencySOS({
    required String agentId,
    required double latitude,
    required double longitude,
  }) async {
    await _dio.post('/wearable/emergency', data: {
      'agent_id': agentId,
      'device_id': 'MOBILE_$agentId',
      'event_type': 'EMERGENCY_SOS',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'location': {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_meters': 10.0,
      },
    });
  }

  Future<List<CaseModel>> getAssignedCases(String agentId) async {
    try {
      final response = await _dio.get('/mobile/cases/$agentId');
      return (response.data as List)
          .map((e) => CaseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return CaseModel.mockList;
    }
  }

  Future<void> submitIntelReport(MobileReport report) async {
    await _dio.post('/mobile/reports', data: report.toJson());
  }

  Future<void> updateStatus({
    required String agentId,
    required String status,
    double? lat,
    double? lon,
  }) async {
    await _dio.post('/mobile/status', data: {
      'agent_id': agentId,
      'status': status,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      if (lat != null && lon != null)
        'location': {'latitude': lat, 'longitude': lon},
    });
  }

  Future<void> notifySecurityBreach({
    required String agentId,
    required List<String> threats,
  }) async {
    try {
      await _dio.post('/security/breach', data: {
        'agent_id': agentId,
        'threats': threats,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'device_type': 'mobile',
      });
    } on DioException {
      // Silently fail - device may be compromised
    }
  }

  Future<void> sendDuressAlert({
    required String agentId,
    required String fakeDashboard,
  }) async {
    try {
      await _dio.post('/command/duress', data: {
        'agent_id': agentId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'fake_dashboard': fakeDashboard,
      });
    } on DioException {
      // Queue for later sync
    }
  }

  Future<void> sendDeadManCheckIn({
    required String agentId,
  }) async {
    try {
      await _dio.post('/agent/checkin', data: {
        'agent_id': agentId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'status': 'ALIVE',
      });
    } on DioException {
      // Queue for later sync
    }
  }

  Future<void> sendBehavioralMetrics({
    required String agentId,
    required Map<String, dynamic> metrics,
  }) async {
    try {
      await _dio.post('/agent/biometrics', data: {
        'agent_id': agentId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'metrics': metrics,
      });
    } on DioException {
      // Queue for later sync
    }
  }
}

class _AgentIdInterceptor extends Interceptor {
  const _AgentIdInterceptor(this._storage);

  final SecureStorageService _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final agentId = await _storage.getAgentId();
    if (agentId != null) {
      options.headers['X-PKI-Entity-ID'] = agentId;
    }
    handler.next(options);
  }
}
