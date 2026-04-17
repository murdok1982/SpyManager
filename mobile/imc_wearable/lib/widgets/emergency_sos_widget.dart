import 'dart:async';

import 'package:flutter/material.dart';
import '../core/theme/wear_colors.dart';
import '../screens/emergency_screen.dart';

class EmergencySosWidget extends StatefulWidget {
  const EmergencySosWidget({
    super.key,
    required this.onSOSConfirmed,
  });

  final VoidCallback onSOSConfirmed;

  @override
  State<EmergencySosWidget> createState() => _EmergencySosWidgetState();
}

class _EmergencySosWidgetState extends State<EmergencySosWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _borderController;
  late Animation<double> _borderOpacity;
  Timer? _holdTimer;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _borderOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _borderController.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails _) {
    setState(() => _holding = true);
    _holdTimer = Timer(const Duration(seconds: 2), () {
      if (_holding && mounted) {
        widget.onSOSConfirmed();
      }
    });
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    _holdTimer?.cancel();
    if (mounted) setState(() => _holding = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      child: AnimatedBuilder(
        animation: _borderOpacity,
        builder: (context, child) {
          return Container(
            width: 72,
            height: 36,
            decoration: BoxDecoration(
              color: _holding
                  ? WearColors.danger.withOpacity(0.4)
                  : WearColors.dangerDark.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: WearColors.danger.withOpacity(_borderOpacity.value),
                width: 2,
              ),
            ),
            child: child,
          );
        },
        child: const Center(
          child: Text(
            'HOLD SOS',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: WearColors.danger,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
