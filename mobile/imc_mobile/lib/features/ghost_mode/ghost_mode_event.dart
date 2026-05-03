/// Events for GhostModeBloc
abstract class GhostModeEvent {}

/// Triggered when a shake is detected
class ShakeDetected extends GhostModeEvent {}

/// Triggered when Morse code input is detected
class MorseCodeDetected extends GhostModeEvent {
  final String code;
  MorseCodeDetected(this.code);
}

/// Toggle ghost mode manually
class ToggleGhostMode extends GhostModeEvent {}
