import 'package:bloc/bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_enclave_storage.dart';

/// BLoC for authentication with duress PIN support
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient _apiClient;
  String? _realPin;
  String? _duressPin;

  AuthBloc(this._apiClient) : super(AuthInitial()) {
    on<LoginWithPin>((event, emit) async {
      emit(AuthLoading());
      
      // Load PINs from secure storage
      _realPin = await SecureEnclaveStorage().read(key: 'real_pin');
      _duressPin = await SecureEnclaveStorage().read(key: 'duress_pin');
      
      if (event.pin == _realPin) {
        emit(AuthSuccess(isDuress: false));
      } else if (event.pin == _duressPin) {
        // Send duress alert to backend
        try {
          await _apiClient.dio.post('/api/auth/duress-alert', data: {
            'timestamp': DateTime.now().toIso8601String(),
            'device_id': await SecureEnclaveStorage().read(key: 'device_id'),
          });
        } catch (_) {
          // Store alert for deferred sync
          await OfflineSyncService().saveUnsynced({
            'type': 'duress_alert',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
        emit(AuthSuccess(isDuress: true));
      } else {
        emit(AuthFailure('Invalid PIN'));
      }
    });

    on<SetPins>((event, emit) async {
      await SecureEnclaveStorage().write(key: 'real_pin', value: event.realPin);
      await SecureEnclaveStorage().write(key: 'duress_pin', value: event.duressPin);
      emit(AuthPinsSet());
    });
  }
}
