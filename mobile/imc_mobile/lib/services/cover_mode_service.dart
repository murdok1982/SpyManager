import 'package:flutter/material.dart';

class CoverModeService extends ChangeNotifier {
  bool _isCoverModeActive = false;
  int _tapCount = 0;
  DateTime? _lastTap;

  bool get isCoverModeActive => _isCoverModeActive;

  void handleSecretTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inSeconds > 2) {
      _tapCount = 0;
    }
    _tapCount++;
    _lastTap = now;
    if (_tapCount >= 3) {
      _isCoverModeActive = !_isCoverModeActive;
      _tapCount = 0;
      notifyListeners();
    }
  }

  void deactivateCoverMode() {
    _isCoverModeActive = false;
    notifyListeners();
  }
}
