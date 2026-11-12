import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:netscan/core/advisory_rules.dart';
import 'package:netscan/core/deep_link.dart';
import 'package:netscan/core/import_report.dart';
import 'package:netscan/core/report.dart';
import 'package:netscan/core/threat_context.dart';
import 'package:netscan/l10n/catalog.dart';

void main() {
  test(
    'AX21 matches exact hardware/region and handles version boundary conservatively',
    () {
      RuleMatch match(
        String version, {
        String region = 'US',
        String hardware = 'V2',
        bool confirmed = true,
      }) => matchOfficialAdvisory(
        model: 'TP-Link Archer AX21',
        hardware: hardware,
        firmware: version,
        region: region,
        detailsConfirmed: confirmed,
      );
      expect(match('1.1.3 Build 20221116').status, Applicability.affected);
      expect(
        match('1.1.4 Build 20230219').status,
        Applicability.outsideKnownRange,
      );
      expect(
        match('1.1.3 Build 20221116', region: 'EU').status,
        Applicability.needsDetails,
      );
      expect(
        match('1.1.3 Build 20221116', hardware: 'V99').status,
        Applicability.needsDetails,
      );
      expect(
        match('1.1.3 Build 20221116', confirmed: false).status,
        Applicability.needsDetails,
      );
      expect(match('1.1.3 Build 20221345').status, Applicability.needsDetails);
      expect(
        match('OEM 1.1.3 Build 20221116').status,
        Applicability.needsDetails,
      );
    },
  );
  test('camera matching does not extend to an OEM suffix or unknown build', () {
    RuleMatch camera(String model, String firmware) => matchOfficialAdvisory(
      model: model,
      hardware: '',
      firmware: firmware,
      region: '',
      detailsConfirmed: true,
    );
    expect(
      camera('Hikvision DS-2CD2122F-I', 'V5.3.0 build 150513').status,
      Applicability.affected,
    );
    expect(
      camera('Hikvision DS-2CD2122F-I-OEM', 'V5.3.0 build 150513').status,
      Applicability.unsupported,
    );
    expect(
      camera('Hikvision DS-2CD2122F-I', 'V5.3.0').status,
      Applicability.needsDetails,
    );
  });
  test('report import is bounded and never starts a scan', () {
    const original = ScanReport(
      host: '192.168.1.2',
      method: 'tcp',
      message: 'scan.complete',
      ports: [PortObservation(80, true)],
    );
    final parsed = importReports(jsonEncode(original.toJson())).single;
    expect(parsed.imported, isTrue);
    expect(parsed.ports.single.port, 80);
    expect(() => importReports('{"schemaVersion": 99}'), throwsFormatException);
    expect(
      () => importReports('x' * (2 * 1024 * 1024 + 1)),
      throwsFormatException,
    );
  });
  test(
    'Nmap imports TCP evidence without treating components as device firmware',
    () {
      final report = importReports(
        '<nmaprun><host endtime="1"><address addr="192.168.1.3" addrtype="ipv4"/>'
        '<ports><port protocol="tcp" portid="22"><state state="open"/><service name="ssh" product="OpenSSH" version="8.9" conf="10">'
        '<cpe>cpe:/a:openbsd:openssh:8.9</cpe></service></port></ports></host></nmaprun>',
      ).single;
      expect(report.identity, isNull);
      expect(report.protocols.single.summary, contains('OpenSSH'));
    },
  );
  test('snapshot comparison only compares ports actually tested in both', () {
    const before = ScanReport(
      host: '192.168.1.1',
      method: 'tcp',
      message: '',
      ports: [PortObservation(23, true), PortObservation(80, false)],
    );
    const after = ScanReport(
      host: '192.168.1.1',
      method: 'tcp',
      message: '',
      ports: [PortObservation(80, true), PortObservation(443, true)],
    );
    final delta = compareReports(before, after);
    expect(delta.newlyReachable, [80]);
    expect(delta.noLongerReachable, isEmpty);
  });
  test('deep links only prefill one private IPv4 target', () {
    expect(
      hostFromLink(Uri.parse('netscan://inspect?host=192.168.1.1')),
      '192.168.1.1',
    );
    for (final link in [
      'netscan://inspect?host=8.8.8.8',
      'netscan://inspect?host=192.168.1.1&scan=true',
      'netscan://inspect?host=192.168.1.1&host=10.0.0.1',
      'https://inspect?host=192.168.1.1',
    ]) {
      expect(hostFromLink(Uri.parse(link)), isNull);
    }
  });
  test(
    'feed failures remain unknown rather than meaning no exploitation',
    () async {
      final data = await fetchThreatContext([
        'CVE-2023-1389',
      ], client: MockClient((_) async => http.Response('', 503)));
      expect(data.values.single.kev, isNull);
      expect(data.values.single.epss, isNull);
    },
  );
  test('KEV and EPSS are independently parsed and dated', () async {
    final data = await fetchThreatContext(
      ['CVE-2023-1389'],
      client: MockClient(
        (request) async => http.Response(
          jsonEncode(
            request.url.host == 'api.first.org'
                ? {
                    'data': [
                      {
                        'cve': 'CVE-2023-1389',
                        'epss': '0.5',
                        'date': '2026-11-12',
                      },
                    ],
                  }
                : {
                    'dateReleased': '2026-11-12',
                    'vulnerabilities': [
                      {'cveID': 'CVE-2023-1389'},
                    ],
                  },
          ),
          200,
        ),
      ),
    );
    expect(data.values.single.kev, isTrue);
    expect(data.values.single.epss, 0.5);
  });
  test('English and Italian catalogs have matching keys and placeholders', () {
    expect(italian.keys.toSet(), english.keys.toSet());
    for (final key in english.keys) {
      expect(english[key], isNotEmpty);
      expect(italian[key], isNotEmpty);
      final regex = RegExp(r'\{[a-zA-Z]+\}');
      expect(
        regex.allMatches(italian[key]!).map((m) => m[0]).toSet(),
        regex.allMatches(english[key]!).map((m) => m[0]).toSet(),
        reason: key,
      );
    }
  });
}
