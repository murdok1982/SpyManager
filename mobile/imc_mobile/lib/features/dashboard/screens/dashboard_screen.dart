import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme/colors.dart';
import '../../../models/agent.dart';
import '../../../models/wearable_event.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../widgets/agent_status_card.dart';
import '../widgets/biometric_widget.dart';
import '../widgets/quick_actions_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<DateTime> _clockStream;
  int _logoTapCount = 0;
  bool _coverModeActive = false;

  @override
  void initState() {
    super.initState();
    _clockStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now().toUtc(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final agent = authState is AuthAuthenticated ? authState.agent : Agent.mock;

    if (_coverModeActive) {
      return _CoverModeApp(
        onDisableCoverMode: () => setState(() => _coverModeActive = false),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppColors.backgroundSecondary,
                  pinned: true,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _Header(
                      clockStream: _clockStream,
                      onLogoTap: _handleLogoTap,
                    ),
                  ),
                  expandedHeight: 80,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      color: AppColors.textSecondary,
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_outlined, size: 20),
                      color: AppColors.textSecondary,
                      onPressed: _handleLogout,
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      AgentStatusCard(agent: agent)
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .slideY(begin: 0.2),
                      const SizedBox(height: 16),
                      BiometricWidget(
                        biometrics: WearableBiometrics.mock,
                        isConnected: true,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.2),
                      const SizedBox(height: 16),
                      _SectionLabel(label: 'QUICK ACTIONS'),
                      const SizedBox(height: 12),
                      QuickActionsBar(
                        onReport: () => context.push(AppConstants.routeIntelReport),
                        onMap: () => context.push(AppConstants.routeMap),
                        onCases: () => context.push(AppConstants.routeCases),
                        onSync: () => context.push(AppConstants.routeWearableSync),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .slideY(begin: 0.2),
                      const SizedBox(height: 16),
                      _SectionLabel(label: 'INTEL ACTIVITY'),
                      const SizedBox(height: 12),
                      _RecentActivityList(),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: _EmergencyFAB(
                onPressed: () => context.push(AppConstants.routeEmergency),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogoTap() {
    _logoTapCount++;
    if (_logoTapCount >= AppConstants.coverModeTapCount) {
      _logoTapCount = 0;
      HapticFeedback.heavyImpact();
      setState(() => _coverModeActive = true);
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'TERMINATE SESSION',
          style: GoogleFonts.robotoMono(
            color: AppColors.textPrimary,
            letterSpacing: 1,
          ),
        ),
        content: const Text('Securely wipe session and return to login?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: GoogleFonts.robotoMono(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text(
              'CONFIRM',
              style: GoogleFonts.robotoMono(color: AppColors.accentCyan),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.clockStream,
    required this.onLogoTap,
  });

  final Stream<DateTime> clockStream;
  final VoidCallback onLogoTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onLogoTap,
            child: Text(
              'IMC',
              style: GoogleFonts.robotoMono(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accentCyan,
                letterSpacing: 4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'OPERATIVE DASHBOARD',
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StreamBuilder<DateTime>(
                stream: clockStream,
                initialData: DateTime.now().toUtc(),
                builder: (context, snap) {
                  final time = snap.data ?? DateTime.now().toUtc();
                  return Text(
                    DateFormat('HH:mm:ss').format(time),
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentCyan,
                    ),
                  );
                },
              ),
              Text(
                'UTC',
                style: GoogleFonts.robotoMono(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          _ConnectionIndicator(),
        ],
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accentGreen,
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withOpacity(0.6),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.1, 1.1),
          duration: 1500.ms,
        );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          color: AppColors.accentCyan,
        ),
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

class _RecentActivityList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _ActivityItem(
        time: '14:32:11',
        text: 'Field report submitted — CASE-ALPHA',
        color: AppColors.accentCyan,
      ),
      _ActivityItem(
        time: '12:18:55',
        text: 'Wearable sync completed — 3 events',
        color: AppColors.accentGreen,
      ),
      _ActivityItem(
        time: '09:44:02',
        text: 'Location beacon — sector 7',
        color: AppColors.warning,
      ),
    ];

    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 32,
                    color: item.color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.text,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          item.time,
                          style: GoogleFonts.robotoMono(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ActivityItem {
  _ActivityItem({
    required this.time,
    required this.text,
    required this.color,
  });

  final String time;
  final String text;
  final Color color;
}

class _EmergencyFAB extends StatelessWidget {
  const _EmergencyFAB({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.heavyImpact();
          onPressed();
        },
        backgroundColor: AppColors.danger,
        child: const Icon(Icons.sos_outlined, size: 28),
        tooltip: 'EMERGENCY SOS',
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.05, 1.05),
          duration: 1200.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _CoverModeApp extends StatelessWidget {
  const _CoverModeApp({required this.onDisableCoverMode});

  final VoidCallback onDisableCoverMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Notes',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NoteItem(
            title: 'Shopping List',
            preview: 'Milk, eggs, bread, coffee...',
            date: 'Today',
          ),
          _NoteItem(
            title: 'Meeting Notes',
            preview: 'Review quarterly targets...',
            date: 'Yesterday',
          ),
          GestureDetector(
            onLongPress: onDisableCoverMode,
            child: _NoteItem(
              title: 'Ideas',
              preview: 'Project brainstorm...',
              date: 'Apr 15',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  const _NoteItem({
    required this.title,
    required this.preview,
    required this.date,
  });

  final String title;
  final String preview;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            preview,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
