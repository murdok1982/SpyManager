import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

/// Behavioral biometrics collection (typing patterns, touch pressure, swipe speed)
class BehavioralBiometricsService {
  final List<Map<String, dynamic>> _events = [];
  DateTime? _lastTapTime;
  Offset? _lastPosition;

  /// Track tap event
  void trackTap(TapDownDetails details) {
    final now = DateTime.now();
    final event = {
      'type': 'tap',
      'x': details.localPosition.dx,
      'y': details.localPosition.dy,
      'pressure': details.kind == PointerDeviceKind.stylus ? details.pressure : 1.0,
      'timestamp': now.millisecondsSinceEpoch,
    };
    
    // Calculate tap interval
    if (_lastTapTime != null) {
      event['interval_ms'] = now.difference(_lastTapTime!).inMilliseconds;
    }
    _lastTapTime = now;
    _events.add(event);
  }

  /// Track swipe/scroll event
  void trackSwipe(DragEndDetails details, Offset startPosition, Offset endPosition) {
    final distance = (endPosition - startPosition).distance;
    final duration = details.velocity.pixelsPerSecond.distance / distance;
    
    _events.add({
      'type': 'swipe',
      'distance': distance,
      'velocity': details.velocity.pixelsPerSecond.distance,
      'duration_ms': duration,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Track typing event (key press duration)
  void trackKeyPress(String key, int pressDurationMs) {
    _events.add({
      'type': 'key_press',
      'key': key,
      'duration_ms': pressDurationMs,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Send collected biometrics to backend
  Future<void> sendToBackend() async {
    if (_events.isEmpty) return;
    
    try {
      await ApiClient().dio.post(
        '/api/biometrics/behavioral',
        data: {
          'events': _events,
          'device_id': await SecureEnclaveStorage().read(key: 'device_id'),
        },
      );
      _events.clear();
    } catch (_) {
      // Store for deferred sync
      await OfflineSyncService().saveUnsynced({
        'type': 'behavioral_biometrics',
        'events': _events,
      });
    }
  }

  /// Get collected events for debugging
  List<Map<String, dynamic>> get events => List.unmodifiable(_events);
}
