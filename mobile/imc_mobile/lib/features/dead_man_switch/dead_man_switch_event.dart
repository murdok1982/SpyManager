/// Events for DeadManSwitchBloc
abstract class DeadManSwitchEvent {}

/// Update check-in interval
class UpdateCheckInInterval extends DeadManSwitchEvent {
  final int intervalMinutes;
  UpdateCheckInInterval(this.intervalMinutes);
}

/// Manually trigger check-in
class CheckIn extends DeadManSwitchEvent {}

/// Trigger Dead Man's Switch
class TriggerDeadManSwitch extends DeadManSwitchEvent {}
