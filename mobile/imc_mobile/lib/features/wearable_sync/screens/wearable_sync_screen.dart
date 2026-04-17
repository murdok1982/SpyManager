import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../models/wearable_event.dart';
import '../services/wearable_channel.dart';

class WearableSyncScreen extends StatefulWidget {
  const WearableSyncScreen({super.key});

  @override
  State<WearableSyncScreen> createState() => _WearableSyncScreenState();
}

class _WearableSyncScreenState extends State<WearableSyncScreen> {
  final _channel = WearableChannel();
  bool _autoSync = true;
  bool _connected = false;
  int? _heartRate;
  int _stressLevel = 0;
  DateTime? _lastSync;
  final List<WearableEvent> _recentEvents = [];
  late StreamSubscription<Map<String, dynamic>> _biometricSub;
  late StreamSubscription<void> _sosSub;

  @override
  void initState() {
    super.initState();
    _channel.initialize();

    _biometricSub = _channel.biometricUpdates.listen((data) {
      if (!mounted) return;
      setState(() {
        _heartRate = data['heart_rate'] as int?;
        _stressLevel = (data['stress_level'] as int?) ?? 0;
        _lastSync = DateTime.now().toUtc();
        _connected = true;
        _recentEvents.insert(
          0,
          WearableEvent(
            agentId: 'AGT-LOCAL',
            type: WearableEventType.heartRate,
            timestamp: DateTime.now().toUtc(),
            heartRate: _heartRate,
            stressLevel: _stressLevel,
          ),
        );
        if (_recentEvents.length > 10) _recentEvents.removeLast();
      });
    });

    _sosSub = _channel.sosActivated.listen((_) {
      if (!mounted) return;
      setState(() {
        _recentEvents.insert(
          0,
          WearableEvent(
            agentId: 'AGT-LOCAL',
            type: WearableEventType.emergencySos,
            timestamp: DateTime.now().toUtc(),
          ),
        );
        if (_recentEvents.length > 10) _recentEvents.removeLast();
      });
    });
  }

  @override
  void dispose() {
    _biometricSub.cancel();
    _sosSub.cancel();
    super.dispose();
  }

  Future<void> _manualSync() async {
    HapticFeedback.mediumImpact();
    try {
      await _channel.sendAgentStatus('ACTIVE', null);
      setState(() {
        _lastSync = DateTime.now().toUtc();
        _connected = true;
      });
    } catch (_) {
      setState(() => _connected = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(
          'WEARABLE SYNC',
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConnectionStatusCard(connected: _connected),
            const SizedBox(height: 16),
            _BiometricCard(
              heartRate: _heartRate,
              stressLevel: _stressLevel,
              lastSync: _lastSync,
            ),
            const SizedBox(height: 16),
            _SyncControlsCard(
              autoSync: _autoSync,
              onAutoSyncChanged: (v) => setState(() => _autoSync = v),
              onManualSync: _manualSync,
            ),
            const SizedBox(height: 16),
            _SectionLabel(label: 'RECENT EVENTS (${_recentEvents.length})'),
            const SizedBox(height: 8),
            if (_recentEvents.isEmpty)
              _EmptyEvents()
            else
              ..._recentEvents.map((e) => _EventTile(event: e)),
          ],
        ),
      ),
    );
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  const _ConnectionStatusCard({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final statusColor = connected ? AppColors.accentGreen : AppColors.textMuted;
    final statusLabel = connected ? 'CONNECTED' : 'DISCONNECTED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: connected
                  ? [
                      BoxShadow(
                        color: statusColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusLabel,
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                connected ? 'IMC WearOS Device' : 'No device detected',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            connected ? Icons.watch_outlined : Icons.watch_off_outlined,
            color: statusColor,
            size: 28,
          ),
        ],
      ),
    );
  }
}

class _BiometricCard extends StatelessWidget {
  const _BiometricCard({
    required this.heartRate,
    required this.stressLevel,
    required this.lastSync,
  });

  final int? heartRate;
  final int stressLevel;
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 14, color: AppColors.accentCyan),
              const SizedBox(width: 8),
              Text(
                'BIOMETRICS',
                style: GoogleFonts.robotoMono(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (lastSync != null)
                Text(
                  DateFormat('HH:mm:ss').format(lastSync!),
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BiometricTile(
                  label: 'HEART RATE',
                  value: heartRate != null ? '$heartRate BPM' : '---',
                  icon: Icons.favorite_outline,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BiometricTile(
                  label: 'STRESS',
                  value: '$stressLevel%',
                  icon: Icons.psychology_outlined,
                  color: _stressColor(stressLevel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _stressColor(int level) {
    if (level < 40) return AppColors.accentGreen;
    if (level < 70) return AppColors.warning;
    return AppColors.danger;
  }
}

class _BiometricTile extends StatelessWidget {
  const _BiometricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.robotoMono(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: 9,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncControlsCard extends StatelessWidget {
  const _SyncControlsCard({
    required this.autoSync,
    required this.onAutoSyncChanged,
    required this.onManualSync,
  });

  final bool autoSync;
  final ValueChanged<bool> onAutoSyncChanged;
  final VoidCallback onManualSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.sync_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                'AUTO SYNC',
                style: GoogleFonts.robotoMono(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Switch(
                value: autoSync,
                onChanged: onAutoSyncChanged,
                activeColor: AppColors.accentCyan,
                activeTrackColor: AppColors.accentCyan.withOpacity(0.3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onManualSync,
              icon: const Icon(Icons.sync, size: 16),
              label: Text(
                'MANUAL SYNC',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentCyan,
                side: const BorderSide(color: AppColors.accentCyan),
                minimumSize: Size.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final WearableEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            color: _eventColor(event.type),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _eventLabel(event),
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('HH:mm:ss').format(event.timestamp),
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _eventIcon(event.type),
            size: 16,
            color: _eventColor(event.type),
          ),
        ],
      ),
    );
  }

  String _eventLabel(WearableEvent e) {
    switch (e.type) {
      case WearableEventType.heartRate:
        return 'HR: ${e.heartRate ?? "?"} BPM  |  Stress: ${e.stressLevel ?? 0}%';
      case WearableEventType.emergencySos:
        return 'EMERGENCY SOS TRIGGERED';
      case WearableEventType.quickReport:
        return 'Quick report: ${e.payload?['report_type'] ?? "UNKNOWN"}';
      case WearableEventType.locationPing:
        return 'Location ping received';
      case WearableEventType.statusUpdate:
        return 'Status update from wearable';
      case WearableEventType.stressLevel:
        return 'Stress update: ${e.stressLevel ?? 0}%';
      case WearableEventType.temperature:
        return 'Temperature: ${e.temperature?.toStringAsFixed(1) ?? "?"} °C';
    }
  }

  Color _eventColor(WearableEventType type) {
    switch (type) {
      case WearableEventType.emergencySos:
        return AppColors.danger;
      case WearableEventType.heartRate:
      case WearableEventType.stressLevel:
        return AppColors.accentCyan;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _eventIcon(WearableEventType type) {
    switch (type) {
      case WearableEventType.emergencySos:
        return Icons.sos_outlined;
      case WearableEventType.heartRate:
        return Icons.favorite_outline;
      case WearableEventType.locationPing:
        return Icons.location_on_outlined;
      default:
        return Icons.watch_outlined;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppColors.accentCyan),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.robotoMono(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Center(
        child: Text(
          'NO EVENTS RECEIVED',
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            color: AppColors.textMuted,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
