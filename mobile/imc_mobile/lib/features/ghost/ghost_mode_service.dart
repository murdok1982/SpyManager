import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shake/shake.dart';
import '../core/storage/secure_enclave_storage.dart';

class GhostModeService {
  GhostModeService._();

  static final GhostModeService instance = GhostModeService._();

  static const int _requiredShakes = 3;
  static const Duration _shakeTimeWindow = Duration(seconds: 5);
  static const String _morseCodeSequence = '.... . .-.. .-.. ---';

  bool _isGhostModeActive = false;
  bool get isGhostModeActive => _isGhostModeActive;

  ShakeDetector? _shakeDetector;
  final List<DateTime> _shakeTimes = [];
  DateTime? _lastMorseTap;
  String _currentMorseInput = '';

  void initialize() {
    _startShakeDetection();
  }

  void _startShakeDetection() {
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: _handleShake,
      shakeThresholdGravity: 2.0,
    );
  }

  void _handleShake() {
    final now = DateTime.now();
    _shakeTimes.add(now);

    _shakeTimes.removeWhere(
      (time) => now.difference(time) > _shakeTimeWindow,
    );

    if (_shakeTimes.length >= _requiredShakes) {
      _activateGhostMode();
      _shakeTimes.clear();
    }
  }

  void handleStatusBarTap() {
    final now = DateTime.now();

    if (_lastMorseTap == null ||
        now.difference(_lastMorseTap!) > const Duration(milliseconds: 500)) {
      _currentMorseInput = '';
    }

    _lastMorseTap = now;
    _currentMorseInput += '.';

    if (_currentMorseInput == _morseCodeSequence) {
      _activateGhostMode();
      _currentMorseInput = '';
    }

    if (_currentMorseInput.length > _morseCodeSequence.length) {
      _currentMorseInput = '';
    }
  }

  void _activateGhostMode() {
    _isGhostModeActive = true;
    SecureEnclaveStorage.instance.saveAgentId('GHOST_MODE');
  }

  void deactivateGhostMode() {
    _isGhostModeActive = false;
  }

  Widget wrapWithGhostMode({required Widget child, required Widget fakeUI}) {
    return ValueListenableBuilder<bool>(
      valueListenable: _GhostModeNotifier.instance,
      builder: (context, isGhost, _) {
        return isGhost ? fakeUI : child;
      },
    );
  }

  Future<void> hideAppFromLauncher() async {
    if (Platform.isAndroid) {
      try {
        await Process.run('pm', ['disable', 'com.imc.mobile']);
      } catch (_) {}
    }
  }

  Future<void> showAppInLauncher() async {
    if (Platform.isAndroid) {
      try {
        await Process.run('pm', ['enable', 'com.imc.mobile']);
      } catch (_) {}
    }
  }
}

class _GhostModeNotifier extends ChangeNotifier {
  _GhostModeNotifier._();

  static final _GhostModeNotifier instance = _GhostModeNotifier._();

  bool _isGhost = false;
  bool get isGhost => _isGhost;

  void setGhostMode(bool value) {
    _isGhost = value;
    notifyListeners();
  }
}
