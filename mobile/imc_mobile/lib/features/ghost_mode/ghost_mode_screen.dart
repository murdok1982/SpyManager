import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ghost Mode: La app se oculta del launcher y muestra una interfaz falsa
/// Invocación: 3 sacudidas o código Morse (... --- ...)
class GhostModeScreen extends StatefulWidget {
  const GhostModeScreen({super.key});

  @override
  State<GhostModeScreen> createState() => _GhostModeScreenState();
}

class _GhostModeScreenState extends State<GhostModeScreen> {
  final _noteController = TextEditingController();
  bool _isGhostMode = false;
  int _shakeCount = 0;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    _loadGhostModeState();
    _initializeShakeDetection();
  }

  Future<void> _loadGhostModeState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGhostMode = prefs.getBool('ghost_mode_enabled') ?? false;
    });
  }

  void _initializeShakeDetection() {
    // TODO: Implementar detección de sacudidas con accelerometro
    // Usar sensors_plus para detectar aceleración
  }

  Future<void> _toggleGhostMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGhostMode = !_isGhostMode;
    });
    await prefs.setBool('ghost_mode_enabled', _isGhostMode);

    if (_isGhostMode) {
      // Ocultar del launcher (Android)
      if (Platform.isAndroid) {
        // TODO: Implementar ocultamiento del launcher via platform channel
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGhostMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Configuración')),
        body: SwitchListTile(
          title: const Text('Modo Fantasma (Ghost Mode)'),
          subtitle: const Text('Oculta la app del launcher'),
          value: _isGhostMode,
          onChanged: (_) => _toggleGhostMode(),
        ),
      );
    }

    // Interfaz falsa: "Bloc de Notas Personal"
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Notas Personales'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _noteController,
              maxLines: 20,
              decoration: const InputDecoration(
                hintText: 'Escribe tus notas personales aquí...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Simular guardado
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nota guardada')),
                );
              },
              child: const Text('Guardar Nota'),
            ),
          ],
        ),
      ),
    );
  }
}
