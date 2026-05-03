import 'package:test/test.dart';
import 'package:imc_mobile/core/utils/anti_tamper.dart';

void main() {
  group('AntiTamper', () {
    test('isDebuggerAttached returns false in release mode', () async {
      // This test will pass in release mode
      final result = await AntiTamper.isDebuggerAttached();
      expect(result, false);
    });

    test('isEmulator returns boolean', () async {
      final result = await AntiTamper.isEmulator();
      expect(result, isA<bool>());
    });
  });
}
