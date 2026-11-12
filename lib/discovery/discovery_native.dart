import 'dart:async';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/services.dart';
import '../core/report.dart';

const declaredServices = [
  '_http._tcp',
  '_https._tcp',
  '_rtsp._tcp',
  '_ssh._tcp',
  '_smb._tcp',
  '_googlecast._tcp',
  '_airplay._tcp',
  '_hap._tcp',
];
Future<void> discoverDevices(
  void Function(String host, String name, String service) found,
) async {
  if (Platform.isAndroid &&
      await const MethodChannel(
            'dev.netscan/permissions',
          ).invokeMethod<bool>('requestLocalNetwork') !=
          true) {
    throw StateError('scan.permission');
  }
  final discoveries = <BonsoirDiscovery>[];
  final subscriptions = <StreamSubscription<BonsoirDiscoveryEvent>>[];
  var started = 0;
  try {
    for (final type in declaredServices) {
      final discovery = BonsoirDiscovery(type: type, printLogs: false);
      discoveries.add(discovery);
      try {
        await discovery.initialize().timeout(const Duration(seconds: 3));
        subscriptions.add(
          discovery.eventStream!.listen((event) {
            if (event is BonsoirDiscoveryServiceFoundEvent) {
              event.service.resolve(discovery.serviceResolver);
            }
            if (event is BonsoirDiscoveryServiceResolvedEvent ||
                event is BonsoirDiscoveryServiceUpdatedEvent) {
              final service = event.service!;
              for (final host in service.hostAddresses.where(isPrivateIPv4)) {
                final clean = service.name.replaceAll(
                  RegExp(r'[\x00-\x1f\x7f]'),
                  '',
                );
                final name = clean.substring(0, clean.length.clamp(0, 200));
                found(host, name, '${service.type}:${service.port}');
              }
            }
          }, onError: (Object error) {}),
        );
        await discovery.start().timeout(const Duration(seconds: 3));
        started++;
      } catch (_) {
        /* Other declared service types can still succeed. */
      }
    }
    if (started == 0) throw StateError('discovery.failed');
    await Future<void>.delayed(const Duration(seconds: 8));
  } finally {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    for (final discovery in discoveries) {
      try {
        await discovery.stop().timeout(const Duration(seconds: 2));
      } catch (_) {
        /* Already stopped. */
      }
    }
  }
}
