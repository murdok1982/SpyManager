import 'dart:io';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/security/secure_enclave_storage.dart';
import '../services/imc_api_service.dart';

class BehavioralBiometricsService {
  BehavioralBiometricsService._();

  static final BehavioralBiometricsService instance =
      BehavioralBiometricsService._();

  final List<_TouchEvent> _touchEvents = [];
  final List<_KeyEvent> _keyEvents = [];
  DateTime? _sessionStart;

  void startSession() {
    _sessionStart = DateTime.now();
    _touchEvents.clear();
    _keyEvents.clear();
    _startSensorCollection();
  }

  void stopSession() {
    _sessionStart = null;
  }

  void recordTouch({
    required double x,
    required double y,
    required Duration pressDuration,
    double? pressure,
  }) {
    _touchEvents.add(_TouchEvent(
      x: x,
      y: y,
      timestamp: DateTime.now(),
      duration: pressDuration,
      pressure: pressure ?? 0.5,
    ));
  }

  void recordKeystroke({
    required Duration keyDownDuration,
    required double intervalToNext,
  }) {
    _keyEvents.add(_KeyEvent(
      timestamp: DateTime.now(),
      duration: keyDownDuration,
      intervalToNext: intervalToNext,
    ));
  }

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  final List<_SwipeEvent> _swipeEvents = [];

  void _startSensorCollection() {
    _accelSubscription = accelerometerEvents.listen((event) {
      // Store background accelerometer data for behavioral analysis
    });
  }

  void recordSwipe({
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    required Duration duration,
  }) {
    _swipeEvents.add(_SwipeEvent(
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
      duration: duration,
      timestamp: DateTime.now(),
    ));
  }

  Future<Map<String, dynamic>> collectMetrics() async {
    final metrics = <String, dynamic>{};

    if (_touchEvents.isNotEmpty) {
      metrics['touch_patterns'] = _analyzeTouchPatterns();
    }

    if (_keyEvents.isNotEmpty) {
      metrics['typing_patterns'] = _analyzeTypingPatterns();
    }

    if (_swipeEvents.isNotEmpty) {
      metrics['swipe_patterns'] = _analyzeSwipePatterns();
    }

    metrics['session_duration_ms'] =
        _sessionStart != null ? DateTime.now().difference(_sessionStart!).inMilliseconds : 0;
    metrics['device_type'] = Platform.isAndroid ? 'android' : 'ios';
    metrics['screen_size'] = 'UNKNOWN';

    return metrics;
  }

  Map<String, dynamic> _analyzeTouchPatterns() {
    if (_touchEvents.isEmpty) return {};

    final pressures = _touchEvents.map((e) => e.pressure);
    final durations = _touchEvents.map((e) => e.duration.inMilliseconds);

    return {
      'avg_pressure': pressures.reduce((a, b) => a + b) / pressures.length,
      'avg_press_duration_ms':
          durations.reduce((a, b) => a + b) / durations.length,
      'sample_count': _touchEvents.length,
    };
  }

  Map<String, dynamic> _analyzeTypingPatterns() {
    if (_keyEvents.isEmpty) return {};

    final durations = _keyEvents.map((e) => e.duration.inMilliseconds);
    final intervals = _keyEvents.map((e) => e.intervalToNext);

    return {
      'avg_key_down_ms':
          durations.reduce((a, b) => a + b) / durations.length,
      'avg_interval_ms':
          intervals.reduce((a, b) => a + b) / intervals.length,
      'sample_count': _keyEvents.length,
    };
  }

  Map<String, dynamic> _analyzeSwipePatterns() {
    if (_swipeEvents.isEmpty) return {};

    final speeds = _swipeEvents.map((e) {
      final distance = sqrt(
        pow(e.endX - e.startX, 2) + pow(e.endY - e.startY, 2),
      );
      return distance / (e.duration.inMilliseconds / 1000);
    });

    return {
      'avg_swipe_speed': speeds.reduce((a, b) => a + b) / speeds.length,
      'sample_count': _swipeEvents.length,
    };
  }

  Future<void> sendMetricsToBackend() async {
    try {
      final agentId = await SecureEnclaveStorage.instance.getAgentId();
      if (agentId == null) return;

      final metrics = await collectMetrics();
      await IMCApiService.instance.sendBehavioralMetrics(
        agentId: agentId,
        metrics: metrics,
      );

      _touchEvents.clear();
      _keyEvents.clear();
      _swipeEvents.clear();
    } catch (_) {}
  }

  Future<void> saveBaseline() async {
    final metrics = await collectMetrics();
    await SecureEnclaveStorage.instance.saveBehavioralBaseline(metrics);
  }

  Future<bool> compareWithBaseline() async {
    try {
      final baseline =
          await SecureEnclaveStorage.instance.getBehavioralBaseline();
      if (baseline == null) return true;

      final current = await collectMetrics();
      return _calculateSimilarity(baseline, current) > 0.8;
    } catch (_) {
      return true;
    }
  }

  double _calculateSimilarity(Map<String, dynamic> a, Map<String, dynamic> b) {
    final keys = a.keys.toSet().intersection(b.keys.toSet());
    if (keys.isEmpty) return 0.0;

    double total = 0;
    for (final key in keys) {
      if (a[key] is num && b[key] is num) {
        total += 1.0 - ((a[key] as num - b[key] as num).abs() /
                (a[key] as num).abs().clamp(1, double.infinity));
      }
    }
    return total / keys.length;
  }
}

class _TouchEvent {
  _TouchEvent({
    required this.x,
    required this.y,
    required this.timestamp,
    required this.duration,
    required this.pressure,
  });

  final double x, y, pressure;
  final DateTime timestamp;
  final Duration duration;
}

class _KeyEvent {
  _KeyEvent({
    required this.timestamp,
    required this.duration,
    required this.intervalToNext,
  });

  final DateTime timestamp;
  final Duration duration;
  intervalToNext;
}

class _SwipeEvent {
  _SwipeEvent({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.duration,
    required this.timestamp,
  });

  final double startX, startY, endX, endY;
  final Duration duration;
  final DateTime timestamp;
}
