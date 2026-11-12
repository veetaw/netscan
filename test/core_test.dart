import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:netscan/core/report.dart';
import 'package:netscan/core/advisories.dart';

void main() {
  test('only accepts canonical private IPv4 addresses', () {
    for (final value in [
      '10.0.0.1',
      '172.16.0.1',
      '172.31.255.254',
      '192.168.1.1',
    ]) {
      expect(isPrivateIPv4(value), isTrue, reason: value);
    }
    for (final value in [
      '8.8.8.8',
      '127.0.0.1',
      '172.32.0.1',
      '172.15.0.1',
      '192.168.1.256',
      '192.168.01.1',
      'router.local',
      '192.168.1.1/path',
      '::1',
    ]) {
      expect(isPrivateIPv4(value), isFalse, reason: value);
    }
  });
  test(
    'NVD sends product only and preserves candidates without confirming CVEs',
    () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'services.nvd.nist.gov');
        expect(request.url.queryParameters['keywordSearch'], 'Example Router');
        expect(request.url.queryParameters.containsKey('ip'), isFalse);
        return http.Response(
          jsonEncode({
            'totalResults': 1,
            'vulnerabilities': [
              {
                'cve': {
                  'id': 'CVE-2025-12345',
                  'descriptions': [
                    {'lang': 'en', 'value': 'Example advisory'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });
      final result = await searchAdvisories('Example Router', client: client);
      expect(result.total, 1);
      expect(result.items.single.id, 'CVE-2025-12345');
      expect(result.items.single.url.scheme, 'https');
    },
  );
  test(
    'rate limiting is an error, never a clean vulnerability result',
    () async {
      final client = MockClient((_) async => http.Response('', 429));
      await expectLater(
        searchAdvisories('Example Router', client: client),
        throwsStateError,
      );
    },
  );
  test('reports do not claim to assess vulnerabilities', () {
    const report = ScanReport(
      host: '192.168.1.1',
      method: 'tcp',
      message: 'Checked',
    );
    expect(report.toJson()['vulnerabilityAssessment'], 'not_performed');
  });
}
