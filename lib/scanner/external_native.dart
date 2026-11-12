import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/address.dart';
import '../core/protocol.dart';
import '../core/report.dart';
import 'protocol_native.dart';
import 'scanner_native.dart';

bool cellularOnly(List<ConnectivityResult> values) =>
    values.isNotEmpty && values.every((v) => v == ConnectivityResult.mobile);

Future<void> _checkNetwork() async {
  if (!(Platform.isAndroid || Platform.isIOS)) {
    throw StateError('external.mobileOnly');
  }
  if (!cellularOnly(await Connectivity().checkConnectivity())) {
    throw StateError('external.network');
  }
}

Future<ScanReport> inspectExternal(String host) async {
  if (!isPublicIPv4(host)) {
    throw ArgumentError(
      'Serve un IPv4 pubblico dedicato alla tua connessione, non un indirizzo condiviso CGNAT.',
    );
  }
  await _checkNetwork();
  final ports = <PortObservation>[];
  const targets = [80, 443, 22, 23, 554, 8554, 8080, 8443];
  for (var i = 0; i < targets.length; i += 2) {
    await _checkNetwork();
    ports.addAll(
      await Future.wait(
        targets
            .skip(i)
            .take(2)
            .map(
              (port) async => PortObservation(port, await probeTcp(host, port)),
            ),
      ),
    );
  }
  final protocols = <ProtocolObservation>[];
  for (final port in [554, 8554]) {
    if (ports.any((p) => p.port == port && p.reachable)) {
      await _checkNetwork();
      protocols.add(await inspectRtsp(host, port));
    }
  }
  await _checkNetwork();
  return ScanReport(
    host: host,
    completedAt: DateTime.now(),
    method: 'external-tcp-cellular-reported',
    ports: ports,
    protocols: protocols,
    message: 'external.complete',
  );
}
