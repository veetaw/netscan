import '../core/protocol.dart';
import 'protocol_native.dart';
import 'upnp_native.dart';
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
        completedAt: DateTime.now(),
        method: 'tcp',
        message:
            'Permesso di rete locale negato. Abilitalo nelle impostazioni per riprovare.',
      );
    }
  }
  final ports = <PortObservation>[];
  const targets = [80, 443, 21, 22, 23, 445, 3389, 554, 8554, 8000, 8080, 8443];
  // At most three simultaneous connections. No credential guessing.
  for (var i = 0; i < targets.length; i += 3) {
    final batch = targets.skip(i).take(3);
    ports.addAll(
      await Future.wait(
        batch.map((port) async {
          return PortObservation(port, await probeTcp(host, port));
        }),
      ),
    );
  }
  final protocols = <ProtocolObservation>[];
  DeviceIdentity? identity;
  for (final port in [554, 8554]) {
    if (ports.any((p) => p.port == port && p.reachable)) {
      protocols.add(await inspectRtsp(host, port));
    }
  }
  for (final port in [80, 8080]) {
    if (ports.any((p) => p.port == port && p.reachable)) {
      final result = await inspectOnvif(host, port);
      protocols.add(result.observation);
      identity ??= result.identity;
    }
  }
  return ScanReport(
    host: host,
    completedAt: DateTime.now(),
    method: 'tcp+ssdp+onvif+rtsp',
    ports: ports,
    protocols: protocols,
    identity: identity,
    upnp: await inspectUpnp(host),
    message:
        'Controllate dodici porte e verificati i protocolli compatibili. '
        'Una porta raggiungibile non dimostra una vulnerabilità. '
        'Esposizione a Internet e accesso cloud/P2P restano da verificare.',
  );
}

Future<bool> probeTcp(String host, int port) async {
  Socket? socket;
  try {
    socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 2),
    );
    return true;
  } on SocketException {
    return false;
  } finally {
    socket?.destroy();
  }
}
