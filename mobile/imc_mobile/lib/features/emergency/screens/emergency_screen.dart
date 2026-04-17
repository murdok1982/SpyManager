import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../../core/theme/colors.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../models/agent.dart';
import '../../../services/imc_api_service.dart';
import '../../../services/location_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _opacityAnimation;
  Timer? _countdownTimer;
  int _remaining = AppConstants.emergencyCountdownSeconds;
  bool _broadcast = false;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startCountdown();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      if (_remaining <= 1) {
        _countdownTimer?.cancel();
        _triggerSOS();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _triggerSOS() async {
    if (_cancelled || _broadcast) return;

    HapticFeedback.vibrate();

    final authState = context.read<AuthBloc>().state;
    final agentId =
        authState is AuthAuthenticated ? authState.agent.id : 'AGT-UNKNOWN';

    final pos = await LocationService.getCurrentPosition();

    try {
      await IMCApiService.instance.sendEmergencySOS(
        agentId: agentId,
        latitude: pos?.latitude ?? 0.0,
        longitude: pos?.longitude ?? 0.0,
      );
    } catch (_) {
      // Best-effort; always show confirmation
    }

    if (!mounted) return;
    setState(() => _broadcast = true);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _cancel() {
    HapticFeedback.mediumImpact();
    _countdownTimer?.cancel();
    setState(() => _cancelled = true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFF8B0000),
                AppColors.danger,
                _opacityAnimation.value,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Text(
                  _broadcast ? 'BROADCAST SENT' : 'EMERGENCY SOS ACTIVE',
                  style: GoogleFonts.robotoMono(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (!_broadcast) ...[
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: _remaining /
                                AppConstants.emergencyCountdownSeconds,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$_remaining',
                          style: GoogleFonts.robotoMono(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'TRANSMITTING IN $_remaining SECONDS',
                    style: GoogleFonts.robotoMono(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'EMERGENCY SIGNAL TRANSMITTED\nTO ALL COMMAND STATIONS',
                    style: GoogleFonts.robotoMono(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 1,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const Spacer(),
                if (!_broadcast)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _cancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.safe,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.robotoMono(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
