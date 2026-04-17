import 'package:flutter/material.dart';
import '../core/theme/wear_colors.dart';
import '../core/channel/phone_channel.dart';
import '../services/haptic_service.dart';

class QuickReportButtons extends StatelessWidget {
  const QuickReportButtons({
    super.key,
    required this.phoneChannel,
    this.compact = false,
  });

  final PhoneChannel phoneChannel;
  final bool compact;

  static const List<_QuickReportAction> _actions = [
    _QuickReportAction(
      label: 'SAFE',
      type: 'SAFE',
      icon: Icons.check_circle_outline,
      color: WearColors.green,
    ),
    _QuickReportAction(
      label: 'INTEL',
      type: 'INTEL',
      icon: Icons.lightbulb_outline,
      color: WearColors.cyan,
    ),
    _QuickReportAction(
      label: 'EXFIL',
      type: 'EXFIL',
      icon: Icons.exit_to_app,
      color: WearColors.amber,
    ),
    _QuickReportAction(
      label: 'COMPRO',
      type: 'COMPROMISED',
      icon: Icons.warning_outlined,
      color: WearColors.danger,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final btnSize = compact ? 44.0 : 56.0;
    final iconSize = compact ? 18.0 : 22.0;
    final fontSize = compact ? 9.0 : 11.0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1,
      children: _actions.map((action) {
        return _QuickButton(
          action: action,
          size: btnSize,
          iconSize: iconSize,
          fontSize: fontSize,
          onTap: () async {
            await HapticService.confirmAction();
            await phoneChannel.sendQuickReport(action.type);
          },
        );
      }).toList(),
    );
  }
}

class _QuickReportAction {
  const _QuickReportAction({
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

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.action,
    required this.size,
    required this.iconSize,
    required this.fontSize,
    required this.onTap,
  });

  final _QuickReportAction action;
  final double size;
  final double iconSize;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: action.color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: iconSize, color: action.color),
            const SizedBox(height: 4),
            Text(
              action.label,
              style: TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: fontSize,
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
