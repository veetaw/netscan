import 'dart:io';
import 'package:flutter/services.dart';
import '../core/report.dart';

Future<ScanReport> inspectHost(String host, {bool https = true}) async {
  if (!isPrivateIPv4(host)) {
    throw ArgumentError('Indirizzo privato IPv4 richiesto.');
  }
  if (Platform.isAndroid) {
    final allowed = await const MethodChannel(
      'dev.netscan/permissions',
    ).invokeMethod<bool>('requestLocalNetwork');
    if (allowed != true) {
      return ScanReport(
        host: host,
        method: 'tcp',
        message:
            'Permesso di rete locale negato. Abilitalo nelle impostazioni per riprovare.',
      );
    }
  }
  final ports = <PortObservation>[];
  // Connections only: no credentials, protocol payloads or exploit probes.
  for (final port in [80, 443, 22, 23]) {
    Socket? socket;
    try {
      socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 2),
      );
      ports.add(PortObservation(port, true));
    } on SocketException {
      ports.add(PortObservation(port, false));
    } finally {
      socket?.destroy();
    }
  }
  return ScanReport(
    host: host,
    method: 'tcp',
    ports: ports,
    message:
        'Controllate quattro porte sul dispositivo indicato. '
        'Una porta raggiungibile non dimostra una vulnerabilità. '
        'Il controllo dalla LAN non misura l’esposizione a Internet.',
  );
}
