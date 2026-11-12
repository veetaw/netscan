enum Applicability { affected, outsideKnownRange, needsDetails, unsupported }

class RuleMatch {
  const RuleMatch(
    this.status, {
    this.cve,
    this.source,
    this.support,
    this.actionKey,
  });
  final Applicability status;
  final String? cve, source, support, actionKey;
}

String _normal(String value) =>
    value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
List<int>? _versionBuild(String input, int dateLength) {
  final match = RegExp(
    '^[vV]?([0-9]{1,5})\\.([0-9]{1,5})\\.([0-9]{1,5}) [bB][uU][iI][lL][dD] ([0-9]{$dateLength})'
    r'(?: rel\.[0-9]+)?$',
  ).firstMatch(input.trim());
  if (match == null) return null;
  final digits = match[4]!;
  final iso = dateLength == 8 ? digits : '20$digits';
  final date = DateTime.tryParse(
    '${iso.substring(0, 4)}-${iso.substring(4, 6)}-${iso.substring(6, 8)}',
  );
  if (date == null ||
      date.year != int.parse(iso.substring(0, 4)) ||
      date.month != int.parse(iso.substring(4, 6)) ||
      date.day != int.parse(iso.substring(6, 8))) {
    return null;
  }
  return [
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
    int.parse(digits),
  ];
}

int _compare(List<int> a, List<int> b) {
  for (var i = 0; i < a.length; i++) {
    final delta = a[i].compareTo(b[i]);
    if (delta != 0) return delta;
  }
  return 0;
}

/// Conservative, reviewed rules. A range match is not an exploit confirmation.
RuleMatch matchOfficialAdvisory({
  required String model,
  required String hardware,
  required String firmware,
  required String region,
  required bool detailsConfirmed,
}) {
  final product = _normal(model);
  if ([
    'TPLINKARCHERAX21',
    'ARCHERAX21',
    'TPLINKARCHERAX21AX1800',
  ].contains(product)) {
    const cve = 'CVE-2023-1389';
    const source = 'https://www.tp-link.com/us/support/faq/3643/';
    const support = 'https://www.tp-link.com/us/support/download/archer-ax21/';
    final version = _versionBuild(firmware, 8);
    final compatible = [
      'V12',
      '12',
      'V2',
      '2',
      'V3',
      '3',
    ].contains(_normal(hardware));
    if (!detailsConfirmed ||
        !compatible ||
        region.toUpperCase() != 'US' ||
        version == null) {
      return const RuleMatch(
        Applicability.needsDetails,
        cve: cve,
        source: source,
        support: support,
        actionKey: 'match.ax21Details',
      );
    }
    return RuleMatch(
      _compare(version, [1, 1, 4, 20230219]) < 0
          ? Applicability.affected
          : Applicability.outsideKnownRange,
      cve: cve,
      source: source,
      support: support,
      actionKey: 'match.ax21Action',
    );
  }
  if (['ASUSRTAX55', 'RTAX55'].contains(product)) {
    const cve = 'CVE-2023-39238';
    const source = 'https://www.twcert.org.tw/tw/cp-132-7354-4e654-1.html';
    const support =
        'https://www.asus.com/networking-iot-servers/wifi-routers/asus-wifi-routers/rt-ax55/helpdesk_bios/';
    if (!detailsConfirmed || firmware.trim().isEmpty) {
      return const RuleMatch(
        Applicability.needsDetails,
        cve: cve,
        source: source,
        support: support,
        actionKey: 'match.asusDetails',
      );
    }
    return RuleMatch(
      firmware.trim() == '3.0.0.4.386_50460'
          ? Applicability.affected
          : Applicability.outsideKnownRange,
      cve: cve,
      source: source,
      support: support,
      actionKey: 'match.asusAction',
    );
  }
  if ([
    'HIKVISIONDS2CD2122FI',
    'DS2CD2122FI',
    'HIKVISIONDS2CD2022FI',
    'DS2CD2022FI',
  ].contains(product)) {
    const cve = 'CVE-2017-7921';
    const source =
        'https://www.cisa.gov/news-events/ics-advisories/icsa-17-124-01';
    const support = 'https://www.hikvision.com/en/support/download/firmware/';
    final version = _versionBuild(firmware, 6);
    if (!detailsConfirmed || version == null) {
      return const RuleMatch(
        Applicability.needsDetails,
        cve: cve,
        source: source,
        support: support,
        actionKey: 'match.hikDetails',
      );
    }
    final affected =
        _compare(version.sublist(0, 3), [5, 2, 0]) >= 0 &&
        _compare(version.sublist(0, 3), [5, 4, 0]) <= 0 &&
        version[3] >= 140721 &&
        version[3] <= 160530;
    return RuleMatch(
      affected ? Applicability.affected : Applicability.outsideKnownRange,
      cve: cve,
      source: source,
      support: support,
      actionKey: 'match.hikAction',
    );
  }
  return const RuleMatch(Applicability.unsupported);
}
