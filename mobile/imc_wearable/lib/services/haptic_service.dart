import 'package:vibration/vibration.dart';

class HapticService {
  HapticService._();

  static Future<void> confirmAction() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50);
    }
  }

  static Future<void> emergencyPulse() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 500]);
    }
  }

  static Future<void> sosCountdown() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }

  static Future<void> reportSent() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 100, 50, 100]);
    }
  }
}
