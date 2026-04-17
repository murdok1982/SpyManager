import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/wear_colors.dart';
import '../core/channel/phone_channel.dart';
import '../services/wear_data_service.dart';
import '../widgets/agent_status_face.dart';
import '../widgets/biometric_display.dart';
import '../widgets/emergency_sos_widget.dart';
import 'biometric_screen.dart';
import 'emergency_screen.dart';
import 'location_beacon_screen.dart';
import 'quick_report_screen.dart';

class WatchfaceScreen extends StatefulWidget {
  const WatchfaceScreen({
    super.key,
    required this.dataService,
    required this.phoneChannel,
  });

  final WearDataService dataService;
  final PhoneChannel phoneChannel;

  @override
  State<WatchfaceScreen> createState() => _WatchfaceScreenState();
}

class _WatchfaceScreenState extends State<WatchfaceScreen> {
  final PageController _pageController = PageController(initialPage: 2);
  int _currentPage = 2;
  Timer? _clockTimer;
  DateTime _utcNow = DateTime.now().toUtc();

  // Page order: 0=Location, 1=QuickReport, 2=AgentStatus (center), 3=Biometric, 4=???
  // As per spec: center=0, right=1(bio), left=2(quickreport)
  // We use 5 pages: 0=Location 1=QuickReport 2=AgentStatus 3=Biometric 4=SOS(placeholder)
  static const int _centerPage = 2;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() => _utcNow = DateTime.now().toUtc());
      },
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToEmergency() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EmergencyScreen(phoneChannel: widget.phoneChannel),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WearColors.bgBase,
      body: GestureDetector(
        onLongPress: _navigateToEmergency,
        child: SafeArea(
          child: Column(
            children: [
              // UTC Clock
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('HH:mm:ss').format(_utcNow),
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: WearColors.cyan,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'UTC',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 9,
                        color: WearColors.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    // Page 0 — Location
                    const LocationBeaconScreen(),
                    // Page 1 — Quick Report (left of center)
                    QuickReportScreen(phoneChannel: widget.phoneChannel),
                    // Page 2 — Agent Status (center)
                    _CenterFace(
                      dataService: widget.dataService,
                      phoneChannel: widget.phoneChannel,
                      onSOSConfirmed: _navigateToEmergency,
                    ),
                    // Page 3 — Biometrics (right of center)
                    BiometricScreen(
                      dataService: widget.dataService,
                      phoneChannel: widget.phoneChannel,
                    ),
                    // Page 4 — Compact biometric summary
                    _BiometricSummaryPage(dataService: widget.dataService),
                  ],
                ),
              ),
              // Page indicators
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PageIndicators(
                  count: 5,
                  current: _currentPage,
                  center: _centerPage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterFace extends StatelessWidget {
  const _CenterFace({
    required this.dataService,
    required this.phoneChannel,
    required this.onSOSConfirmed,
  });

  final WearDataService dataService;
  final PhoneChannel phoneChannel;
  final VoidCallback onSOSConfirmed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AgentStatusFace(dataService: dataService),
        const SizedBox(height: 12),
        BiometricDisplay(dataService: dataService),
        const SizedBox(height: 14),
        EmergencySosWidget(onSOSConfirmed: onSOSConfirmed),
      ],
    );
  }
}

class _BiometricSummaryPage extends StatelessWidget {
  const _BiometricSummaryPage({required this.dataService});

  final WearDataService dataService;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SUMMARY',
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 11,
              color: WearColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          BiometricDisplay(dataService: dataService),
        ],
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({
    required this.count,
    required this.current,
    required this.center,
  });

  final int count;
  final int current;
  final int center;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isCenter = i == center;
        final isActive = i == current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: isCenter ? 8 : 5,
          height: isCenter ? 8 : 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? WearColors.cyan
                : isCenter
                    ? WearColors.textSecondary
                    : WearColors.textMuted,
          ),
        );
      }),
    );
  }
}
