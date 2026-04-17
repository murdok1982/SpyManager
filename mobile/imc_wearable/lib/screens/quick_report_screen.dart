import 'package:flutter/material.dart';
import '../core/theme/wear_colors.dart';
import '../core/channel/phone_channel.dart';
import '../services/haptic_service.dart';

class QuickReportScreen extends StatelessWidget {
  const QuickReportScreen({super.key, required this.phoneChannel});

  final PhoneChannel phoneChannel;

  static const List<_Action> _actions = [
    _Action(
      label: 'SAFE',
      type: 'SAFE',
      icon: Icons.check_circle_outline,
      color: WearColors.green,
    ),
    _Action(
      label: 'INTEL',
      type: 'INTEL',
      icon: Icons.lightbulb_outline,
      color: WearColors.cyan,
    ),
    _Action(
      label: 'EXFIL',
      type: 'EXFIL',
      icon: Icons.exit_to_app,
      color: WearColors.amber,
    ),
    _Action(
      label: 'COMPRO',
      type: 'COMPROMISED',
      icon: Icons.warning_outlined,
      color: WearColors.danger,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WearColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              const Text(
                'QUICK REPORT',
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 11,
                  color: WearColors.textSecondary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: _actions.map((action) {
                    return _ActionButton(
                      action: action,
                      onTap: () async {
                        await HapticService.confirmAction();
                        await phoneChannel.sendQuickReport(action.type);
                        await HapticService.reportSent();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action {
  const _Action({
    required this.label,
    required this.type,
    required this.icon,
    required this.color,
  });

  final String label;
  final String type;
  final IconData icon;
  final Color color;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onTap});

  final _Action action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: action.color.withOpacity(0.5), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 26, color: action.color),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: action.color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
