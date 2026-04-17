import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _agentIdController = TextEditingController();
  final _pinController = TextEditingController();
  bool _pinObscured = true;
  late AnimationController _matrixController;

  @override
  void initState() {
    super.initState();
    _matrixController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _agentIdController.dispose();
    _pinController.dispose();
    _matrixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppConstants.routeDashboard);
        }
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.robotoMono(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AppColors.backgroundCard,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Stack(
          children: [
            _MatrixBackground(controller: _matrixController),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 48),
                      _buildForm(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                      const SizedBox(height: 32),
                      _buildClassifiedNotice(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accentCyan, width: 2),
            color: AppColors.backgroundCard,
          ),
          child: const Icon(
            Icons.shield_outlined,
            size: 40,
            color: AppColors.accentCyan,
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 24),
        Text(
          'IMC',
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.accentCyan,
            letterSpacing: 8,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Text(
          'INTELLIGENCE MANAGEMENT COMMAND',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 3,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 8),
        Container(
          height: 1,
          width: 200,
          color: AppColors.borderActive.withOpacity(0.5),
        ).animate().fadeIn(delay: 600.ms).scaleX(),
      ],
    );
  }

  Widget _buildForm() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading =
            state is AuthLoading || state is AuthVerifyingCertificate;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AGENT AUTHENTICATION',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _agentIdController,
                enabled: !isLoading,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[A-Za-z0-9\-_]'),
                  ),
                  UpperCaseTextFormatter(),
                ],
                style: GoogleFonts.robotoMono(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
                decoration: const InputDecoration(
                  labelText: 'AGENT ID',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                  hintText: 'AGT-XXX',
                ),
                validator: Validators.validateAgentId,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pinController,
                enabled: !isLoading,
                obscureText: _pinObscured,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.robotoMono(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  labelText: 'PIN CODE',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  counterText: '',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _pinObscured = !_pinObscured),
                    icon: Icon(
                      _pinObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                validator: Validators.validatePin,
              ),
              if (state is AuthVerifyingCertificate) ...[
                const SizedBox(height: 20),
                _VerifyingCertificateWidget(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading =
            state is AuthLoading || state is AuthVerifyingCertificate;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCyan,
              foregroundColor: AppColors.backgroundPrimary,
              disabledBackgroundColor: AppColors.accentCyan.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.backgroundPrimary,
                    ),
                  )
                : Text(
                    'AUTHENTICATE',
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: AppColors.backgroundPrimary,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildClassifiedNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
        color: AppColors.warning.withOpacity(0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Text(
            'CLASSIFIED SYSTEM — AUTHORIZED ACCESS ONLY',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.warning,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      HapticFeedback.mediumImpact();
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              agentId: _agentIdController.text.trim(),
              pin: _pinController.text,
            ),
          );
    }
  }
}

class _VerifyingCertificateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentCyan.withOpacity(0.05),
        border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentCyan,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'VERIFYING PKI CERTIFICATE...',
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color: AppColors.accentCyan,
              letterSpacing: 1.5,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(duration: 400.ms)
              .then()
              .fadeOut(duration: 400.ms),
        ],
      ),
    );
  }
}

class _MatrixBackground extends StatelessWidget {
  const _MatrixBackground({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _MatrixPainter(controller.value),
          size: MediaQuery.sizeOf(context),
        );
      },
    );
  }
}

class _MatrixPainter extends CustomPainter {
  _MatrixPainter(this.progress);

  final double progress;

  static final _paint = Paint()
    ..color = const Color(0xFF00FF87).withOpacity(0.04)
    ..style = PaintingStyle.fill;

  static const _chars = '01ABCDEF';
  static final _rng = math.Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    const charSize = 14.0;
    final cols = (size.width / charSize).ceil();
    final rows = (size.height / charSize).ceil();

    for (int col = 0; col < cols; col++) {
      for (int row = 0; row < rows; row++) {
        final seed = col * 7 + row * 13;
        final rng = math.Random(seed + (progress * 10).floor());
        if (rng.nextDouble() > 0.85) {
          final char = _chars[rng.nextInt(_chars.length)];
          final tp = TextPainter(
            text: TextSpan(
              text: char,
              style: TextStyle(
                color: const Color(0xFF00FF87).withOpacity(
                  0.03 + rng.nextDouble() * 0.05,
                ),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(col * charSize, row * charSize));
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MatrixPainter old) => old.progress != progress;
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
