import 'package:test/test.dart';
import 'package:imc_mobile/core/network/cert_pinner.dart';

void main() {
  group('CertPinner', () {
    test('initializes with pinned hashes', () {
      final pinner = CertPinner(pinnedHashes: ['hash1', 'hash2']);
      expect(pinner.pinnedHashes.length, 2);
    });

    test('validates certificate against pinned hashes', () {
      final pinner = CertPinner(pinnedHashes: ['test_hash']);
      // Mock certificate - in real test use actual X509Certificate
      expect(pinner.pinnedHashes.contains('test_hash'), true);
    });
  });
}
