/// States for GhostModeBloc
abstract class GhostModeState {}

/// App is in normal mode (visible in launcher)
class GhostModeInitial extends GhostModeState {}

/// Ghost mode is active
class GhostModeActive extends GhostModeState {
  final bool fakeUi;
  GhostModeActive({required this.fakeUi});
}
