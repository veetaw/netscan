import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netscan/core/address.dart';
import 'package:netscan/scanner/external_native.dart';

void main() {
  test(
    'external checks reject private, CGNAT, documentation and multicast addresses',
    () {
      for (final ip in [
        '192.168.1.1',
        '10.0.0.1',
        '172.16.0.1',
        '100.64.0.1',
        '100.127.255.254',
        '127.0.0.1',
        '169.254.1.1',
        '192.0.2.1',
        '198.51.100.1',
        '203.0.113.1',
        '198.18.1.1',
        '224.0.0.1',
        '255.255.255.255',
        '0.0.0.0',
        '01.2.3.4',
        '8.8.8.8:80',
        'example.org',
      ]) {
        expect(isPublicIPv4(ip), isFalse, reason: ip);
      }
      // Validation only. These addresses are never probed by this test.
      expect(isPublicIPv4('8.8.8.8'), isTrue);
    },
  );
  test('WAN checks require unambiguous cellular connectivity', () {
    expect(cellularOnly([ConnectivityResult.mobile]), isTrue);
    for (final network in [
      <ConnectivityResult>[],
      [ConnectivityResult.wifi],
      [ConnectivityResult.mobile, ConnectivityResult.wifi],
      [ConnectivityResult.mobile, ConnectivityResult.vpn],
      [ConnectivityResult.mobile, ConnectivityResult.other],
      [ConnectivityResult.none],
    ]) {
      expect(cellularOnly(network), isFalse);
    }
  });
  test('non-mobile desktop cannot silently perform a WAN scan', () async {
    await expectLater(inspectExternal('8.8.8.8'), throwsStateError);
  });
}
