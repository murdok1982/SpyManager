/// States for AuthBloc
abstract class AuthState {}

/// Initial authentication state
class AuthInitial extends AuthState {}

/// Authentication in progress
class AuthLoading extends AuthState {}

/// Authentication successful
class AuthSuccess extends AuthState {
  final bool isDuress;
  AuthSuccess({required this.isDuress});
}

/// Authentication failed
class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

/// PINs successfully set
class AuthPinsSet extends AuthState {}
