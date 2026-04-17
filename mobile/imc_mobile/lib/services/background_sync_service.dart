import 'dart:async';

import '../models/wearable_event.dart';
import 'imc_api_service.dart';

class BackgroundSyncService {
  BackgroundSyncService._();

  static final BackgroundSyncService instance = BackgroundSyncService._();

  final List<WearableEvent> _pendingEvents = [];
  Timer? _syncTimer;
  bool _running = false;

  void start() {
    if (_running) return;
    _running = true;
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _flush(),
    );
  }

  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _running = false;
  }

  void enqueue(WearableEvent event) {
    _pendingEvents.add(event);
  }

  Future<void> _flush() async {
    if (_pendingEvents.isEmpty) return;
    final batch = List<WearableEvent>.from(_pendingEvents);
    _pendingEvents.clear();

    for (final event in batch) {
      try {
        await IMCApiService.instance.sendWearableEvent(event);
      } catch (_) {
        // Re-enqueue failed events to retry on next tick
        _pendingEvents.add(event);
      }
    }
  }
}
