import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dead Man's Switch: Alertas si el agente no hace check-in
class DeadManSwitchScreen extends StatefulWidget {
  const DeadManSwitchScreen({super.key});

  @override
  State<DeadManSwitchScreen> createState() => _DeadManSwitchScreenState();
}

class _DeadManSwitchScreenState extends State<DeadManSwitchScreen> {
  bool _enabled = false;
  int _hoursThreshold = 48;
  bool _autoWipe = false;
  DateTime? _lastCheckin;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool('dms_enabled') ?? false;
      _hoursThreshold = prefs.getInt('dms_hours') ?? 48;
      _autoWipe = prefs.getBool('dms_auto_wipe') ?? false;
      final lastCheckinStr = prefs.getString('dms_last_checkin');
      if (lastCheckinStr != null) {
        _lastCheckin = DateTime.parse(lastCheckinStr);
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dms_enabled', _enabled);
    await prefs.setInt('dms_hours', _hoursThreshold);
    await prefs.setBool('dms_auto_wipe', _autoWipe);
  }

  Future<void> _performCheckin() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('dms_last_checkin', now.toIso8601String());
    setState(() {
      _lastCheckin = now;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in realizado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hoursSinceCheckin = _lastCheckin != null
        ? DateTime.now().difference(_lastCheckin!).inHours
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Dead Man\'s Switch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estado actual
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado: ${_enabled ? "ACTIVO" : "INACTIVO"}',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _enabled ? Colors.green : Colors.grey)),
                  const SizedBox(height: 8),
                  if (_lastCheckin != null)
                    Text(
                        'Último check-in: ${hoursSinceCheckin}h atrás'),
                  if (hoursSinceCheckin != null && hoursSinceCheckin > _hoursThreshold)
                    const Text('¡ALERTA! Se ha superado el umbral',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Activar/Desactivar
          SwitchListTile(
            title: const Text('Activar Dead Man\'s Switch'),
            value: _enabled,
            onChanged: (value) {
              setState(() => _enabled = value);
              _saveSettings();
            },
          ),

          // Umbral de horas
          ListTile(
            title: const Text('Umbral de horas'),
            subtitle: Slider(
              value: _hoursThreshold.toDouble(),
              min: 12,
              max: 168,
              divisions: 13,
              label: '$_hoursThreshold h',
              onChanged: (value) {
                setState(() => _hoursThreshold = value.round());
                _saveSettings();
              },
            ),
            trailing: Text('$_hoursThreshold h'),
          ),

          // Auto-wipe
          SwitchListTile(
            title: const Text('Auto-Wipe al superar umbral'),
            subtitle: const Text('Borra datos locales automáticamente'),
            value: _autoWipe,
            onChanged: (value) {
              setState(() => _autoWipe = value);
              _saveSettings();
            },
          ),

          const SizedBox(height: 24),

          // Botón de check-in manual
          ElevatedButton.icon(
            onPressed: _performCheckin,
            icon: const Icon(Icons.check_circle),
            label: const Text('Realizar Check-In Ahora'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
