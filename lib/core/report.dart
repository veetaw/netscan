class PortObservation {
  const PortObservation(this.port, this.reachable);
  final int port;
  final bool reachable;
}

class ScanReport {
  const ScanReport({
    required this.host,
    required this.method,
    required this.message,
    this.ports = const [],
    this.httpStatus,
  });
  final String host;
  final String method;
  final String message;
  final List<PortObservation> ports;
  final int? httpStatus;
  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'host': host,
    'method': method,
    'message': message,
    'httpStatus': httpStatus,
    'ports': [
      for (final p in ports) {'port': p.port, 'reachable': p.reachable},
    ],
    'vulnerabilityAssessment': 'not_performed',
  };
}

bool isPrivateIPv4(String value) {
  final parts = value.split('.');
  if (parts.length != 4) return false;
  final octets = <int>[];
  for (final p in parts) {
    if (!RegExp(r'^(0|[1-9][0-9]{0,2})$').hasMatch(p)) return false;
    final n = int.parse(p);
    if (n > 255) return false;
    octets.add(n);
  }
  return octets[0] == 10 ||
      (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) ||
      (octets[0] == 192 && octets[1] == 168);
}
