import 'dart:convert';
import 'package:xml/xml.dart';
import 'address.dart';
import 'protocol.dart';
import 'report.dart';
import 'upnp.dart';

String _text(Object? value, [int max = 8192]) {
  if (value is! String || value.length > max) {
    throw const FormatException('Invalid text');
  }
  return value;
}

ScanReport reportFromJson(Map<String, dynamic> data, {bool imported = true}) {
  if (data['schemaVersion'] != 1) {
    throw const FormatException('Unsupported report version');
  }
  final host = _text(data['host'], 64);
  if (ipv4Number(host) == null) throw const FormatException('Invalid host');
  final rawPorts = data['ports'] as List<dynamic>? ?? [];
  if (rawPorts.length > 1024) throw const FormatException('Too many ports');
  final ports = <PortObservation>[];
  for (final p in rawPorts.cast<Map<String, dynamic>>()) {
    final port = p['port'];
    if (port is! int || port < 1 || port > 65535 || p['reachable'] is! bool) {
      throw const FormatException('Invalid port');
    }
    ports.add(PortObservation(port, p['reachable'] as bool));
  }
  final rawProtocols = data['protocols'] as List<dynamic>? ?? [];
  if (rawProtocols.length > 128) {
    throw const FormatException('Too many protocols');
  }
  final protocols = [
    for (final p in rawProtocols.cast<Map<String, dynamic>>())
      ProtocolObservation(
        protocol: _text(p['protocol'], 64),
        port: p['port'] as int,
        summary: _text(p['summary']),
        status: p['status'] as int?,
        metadataWithoutAuth: p['metadataWithoutAuth'] == true,
        evidence: p['evidence'] == null ? null : _text(p['evidence'], 1024),
      ),
  ];
  DeviceIdentity? identity;
  if (data['identity'] case final Map<String, dynamic> i) {
    identity = DeviceIdentity(
      _text(i['manufacturer'], 200),
      _text(i['model'], 200),
      _text(i['firmware'], 200),
    );
  }
  UpnpObservation? upnp;
  if (data['upnp'] case final Map<String, dynamic> u) {
    final list = u['mappings'] as List<dynamic>? ?? [];
    if (list.length > 128) throw const FormatException('Too many mappings');
    upnp = UpnpObservation(
      detected: u['detected'] == true,
      message: _text(u['message']),
      mappingListComplete: u['mappingListComplete'] == true,
      mappings: [
        for (final m in list.cast<Map<String, dynamic>>())
          PortMapping(
            externalPort: _text(m['externalPort'], 10),
            protocol: _text(m['protocol'], 10),
            internalClient: _text(m['internalClient'], 64),
            internalPort: _text(m['internalPort'], 10),
            enabled: m['enabled'] == true,
          ),
      ],
    );
  }
  return ScanReport(
    host: host,
    method: _text(data['method'], 100),
    message: _text(data['message']),
    ports: ports,
    protocols: protocols,
    identity: identity,
    upnp: upnp,
    imported: imported,
    completedAt: DateTime.tryParse('${data['completedAtUtc']}'),
    httpStatus: data['httpStatus'] as int?,
  );
}

List<ScanReport> importReports(String content) {
  if (utf8.encode(content).length > 2 * 1024 * 1024) {
    throw const FormatException('File too large');
  }
  final text = content.trim();
  if (text.startsWith('<')) return _importNmap(text);
  final decoded = jsonDecode(text);
  final List<dynamic> reports;
  if (decoded is Map<String, dynamic> &&
      decoded['schemaVersion'] == 1 &&
      decoded['host'] != null) {
    reports = [decoded];
  } else if (decoded is Map<String, dynamic> &&
      decoded['format'] == 'netscan-inventory-v1') {
    reports = (decoded['reports'] as List<dynamic>);
  } else {
    throw const FormatException('Unsupported format');
  }
  if (reports.length > 512) throw const FormatException('Too many reports');
  return [
    for (final report in reports)
      reportFromJson(report as Map<String, dynamic>),
  ];
}

List<ScanReport> _importNmap(String text) {
  final doc = XmlDocument.parse(text);
  if (doc.rootElement.name.local != 'nmaprun') {
    throw const FormatException('Not Nmap XML');
  }
  final hosts = doc.rootElement.findElements('host').toList();
  if (hosts.length > 512) throw const FormatException('Too many hosts');
  final output = <ScanReport>[];
  for (final host in hosts) {
    final ips = host
        .findElements('address')
        .where((e) => e.getAttribute('addrtype') == 'ipv4');
    if (ips.isEmpty) continue;
    final ip = ips.first.getAttribute('addr') ?? '';
    if (ipv4Number(ip) == null) continue;
    final entries = host
        .findAllElements('port')
        .where((e) => e.getAttribute('protocol') == 'tcp')
        .toList();
    if (entries.length > 1024) throw const FormatException('Too many ports');
    final ports = <PortObservation>[];
    final fingerprints = <ProtocolObservation>[];
    for (final entry in entries) {
      final port = int.tryParse(entry.getAttribute('portid') ?? '');
      if (port == null || port < 1 || port > 65535) continue;
      final open =
          entry.findElements('state').firstOrNull?.getAttribute('state') ==
          'open';
      ports.add(PortObservation(port, open));
      final service = entry.findElements('service').firstOrNull;
      if (service != null && open) {
        final product = service.getAttribute('product') ?? '';
        final version = service.getAttribute('version') ?? '';
        final cpes = service
            .findElements('cpe')
            .map((e) => e.innerText)
            .join(', ');
        final evidence =
            'Nmap: ${service.getAttribute('name') ?? 'unknown'}; product=$product; version=$version; CPE=$cpes; confidence=${service.getAttribute('conf') ?? 'unknown'}/10';
        fingerprints.add(
          ProtocolObservation(
            protocol: 'Nmap',
            port: port,
            summary: _text(evidence),
          ),
        );
      }
    }
    output.add(
      ScanReport(
        host: ip,
        method: 'nmap-xml-import',
        message: 'import.nmapCoverage',
        ports: ports,
        protocols: fingerprints,
        imported: true,
        completedAt: DateTime.fromMillisecondsSinceEpoch(
          (int.tryParse(host.getAttribute('endtime') ?? '') ?? 0) * 1000,
          isUtc: true,
        ),
      ),
    );
  }
  return output;
}

class ReportDelta {
  const ReportDelta(this.newlyReachable, this.noLongerReachable);
  final List<int> newlyReachable, noLongerReachable;
}

ReportDelta compareReports(ScanReport previous, ScanReport current) {
  if (previous.host != current.host || previous.method != current.method) {
    throw const FormatException('Different target or profile');
  }
  final before = {for (final p in previous.ports) p.port: p.reachable};
  final after = {for (final p in current.ports) p.port: p.reachable};
  return ReportDelta(
    [
      for (final p in after.keys)
        if (after[p] == true && before[p] == false) p,
    ],
    [
      for (final p in before.keys)
        if (before[p] == true && after[p] == false) p,
    ],
  );
}
