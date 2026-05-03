/// States for DeadManSwitchBloc
abstract class DeadManSwitchState {}

/// Initial state
class DeadManSwitchInitial extends DeadManSwitchState {}

/// Interval updated
class DeadManSwitchUpdated extends DeadManSwitchState {
  final int intervalMinutes;
  DeadManSwitchUpdated({required this.intervalMinutes});
}

/// Check-in successful
class DeadManSwitchCheckedIn extends DeadManSwitchState {
  final int lastCheckIn;
  DeadManSwitchCheckedIn({required this.lastCheckIn});
}

/// Dead Man's Switch triggered
class DeadManSwitchTriggered extends DeadManSwitchState {}
