import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'ghost_mode_event.dart';
import 'ghost_mode_state.dart';

/// BLoC for managing ghost mode state and secret invocation
class GhostModeBloc extends Bloc<GhostModeEvent, GhostModeState> {
  final List<double> _shakeTimestamps = [];
  StreamSubscription? _accelerometerSubscription;
  static const int _requiredShakes = 3;
  static const int _shakeWindowMs = 2000; // 2 seconds to complete shakes

  GhostModeBloc() : super(GhostModeInitial()) {
    on<ShakeDetected>((event, emit) async {
      final now = DateTime.now().millisecondsSinceEpoch;
      _shakeTimestamps.add(now.toDouble());
      
      // Remove old timestamps outside the window
      _shakeTimestamps.removeWhere((ts) => now - ts > _shakeWindowMs);
      
      if (_shakeTimestamps.length >= _requiredShakes) {
        _shakeTimestamps.clear();
        if (state is GhostModeInitial) {
          emit(GhostModeActive(fakeUi: false));
        } else if (state is GhostModeActive && !(state as GhostModeActive).fakeUi) {
          emit(GhostModeActive(fakeUi: true));
        }
      }
    });

    on<MorseCodeDetected>((event, emit) {
      // Secret Morse code pattern: ... --- ... (SOS)
      const secretPattern = '...---...';
      if (event.code == secretPattern) {
        if (state is GhostModeInitial) {
          emit(GhostModeActive(fakeUi: false));
        } else {
          emit(GhostModeInitial());
        }
      }
    });

    on<ToggleGhostMode>((event, emit) {
      if (state is GhostModeInitial) {
        emit(GhostModeActive(fakeUi: false));
      } else {
        emit(GhostModeInitial());
      }
    });

    // Start listening to accelerometer for shake detection
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      // Detect shake: acceleration magnitude > 15 m/s²
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude > 15) {
        add(ShakeDetected());
      }
    });
  }

  @override
  Future<void> close() {
    _accelerometerSubscription?.cancel();
    return super.close();
  }
}
