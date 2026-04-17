import 'package:flutter/material.dart';
import '../core/theme/wear_colors.dart';
import '../core/channel/phone_channel.dart';
import '../services/haptic_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key, required this.phoneChannel});

  final PhoneChannel phoneChannel;

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _bgOpacity;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _bgOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    HapticService.emergencyPulse();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _confirmSOS() async {
    if (_sent) return;
    await HapticService.emergencyPulse();
    await widget.phoneChannel.sendEmergencyToPhone();
    if (mounted) {
      setState(() => _sent = true);
    }
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WearColors.bgBase,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -200) {
            _confirmSOS();
          }
        },
        child: AnimatedBuilder(
          animation: _bgOpacity,
          builder: (context, child) {
            return Container(
              color: Color.lerp(
                WearColors.dangerDark,
                WearColors.danger,
                _bgOpacity.value,
              ),
              child: child,
            );
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _sent ? 'SENT' : 'SOS ACTIVE',
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  if (!_sent)
                    const Text(
                      'SWIPE UP TO CONFIRM',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 11,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
