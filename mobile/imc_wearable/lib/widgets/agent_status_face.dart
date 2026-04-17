import 'package:flutter/material.dart';
import '../core/theme/wear_colors.dart';
import '../services/wear_data_service.dart';

class AgentStatusFace extends StatefulWidget {
  const AgentStatusFace({super.key, required this.dataService});

  final WearDataService dataService;

  @override
  State<AgentStatusFace> createState() => _AgentStatusFaceState();
}

class _AgentStatusFaceState extends State<AgentStatusFace>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  late Animation<double> _dotOpacity;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _dotOpacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _dotController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.dataService,
      builder: (context, _) {
        final status = widget.dataService.agentStatus;
        final statusColor = widget.dataService.statusColor;
        final caseId = widget.dataService.caseId;
        final isActive = status == 'ACTIVE';
        final isCompromised = status == 'COMPROMISED';

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
              ),
            ),
            // Main circle
            _StatusCircle(
              color: statusColor,
              isCompromised: isCompromised,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: WearColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (caseId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      caseId.length > 10
                          ? '${caseId.substring(0, 10)}...'
                          : caseId,
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 10,
                        color: WearColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Pulsing dot top-right when ACTIVE
            if (isActive)
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedBuilder(
                  animation: _dotOpacity,
                  builder: (_, __) => Opacity(
                    opacity: _dotOpacity.value,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: WearColors.statusActive,
                        boxShadow: [
                          BoxShadow(
                            color: WearColors.statusActive.withOpacity(0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatusCircle extends StatefulWidget {
  const _StatusCircle({
    required this.color,
    required this.isCompromised,
    required this.child,
  });

  final Color color;
  final bool isCompromised;
  final Widget child;

  @override
  State<_StatusCircle> createState() => _StatusCircleState();
}

class _StatusCircleState extends State<_StatusCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isCompromised) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StatusCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompromised && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isCompromised && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.15),
          border: Border.all(color: widget.color, width: 2),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
