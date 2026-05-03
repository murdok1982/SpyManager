import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/bloc/auth_bloc.dart';

/// Duress PIN: PIN secundario que muestra dashboard falso pero alerta silenciosamente
class DuressPinScreen extends StatefulWidget {
  const DuressPinScreen({super.key});

  @override
  State<DuressPinScreen> createState() => _DuressPinScreenState();
}

class _DuressPinScreenState extends State<DuressPinScreen> {
  final _pinController = TextEditingController();
  bool _isDuressPin = false;

  void _checkPin(String pin) {
    // Verificar si es Duress PIN (último dígito +1 del PIN real)
    // En producción, esto se validaría contra el backend
    BlocProvider.of<AuthBloc>(context).add(
      AuthDuressPinEntered(pin: pin),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio de Sesión'),
        backgroundColor: Colors.green, // Color normal para no alertar
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ingrese su PIN de acceso',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'PIN',
                counterText: '',
              ),
              onSubmitted: _checkPin,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _checkPin(_pinController.text),
              child: const Text('Ingresar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// BLoC event para Duress PIN
class AuthDuressPinEntered extends AuthEvent {
  final String pin;
  const AuthDuressPinEntered({required this.pin});
}

/// BLoC handler para Duress PIN
void handleDuressPin(AuthDuressPinEntered event, Emitter<AuthState> emit) async {
  // Verificar si es duress PIN
  if (_isDuressPin(event.pin)) {
    // Enviar alerta silenciosa al backend
    await _sendSilentAlert();

    // Emitir estado de dashboard falso
    emit(AuthSuccessFakeDashboard());
  } else {
    // Login normal
    // ... lógica normal de login
  }
}

Future<void> _sendSilentAlert() async {
  // Enviar alerta silenciosa al comando
  try {
    await apiClient.post('/api/v1/security/duress-alert', data: {
      'timestamp': DateTime.now().toIso8601String(),
      'location': await _getCurrentLocation(),
    });
  } catch (_) {}
}
