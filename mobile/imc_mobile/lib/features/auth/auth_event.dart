/// Events for AuthBloc
abstract class AuthEvent {}

/// Login with PIN
class LoginWithPin extends AuthEvent {
  final String pin;
  LoginWithPin(this.pin);
}

/// Set real and duress PINs
class SetPins extends AuthEvent {
  final String realPin;
  final String duressPin;
  SetPins(this.realPin, this.duressPin);
}
