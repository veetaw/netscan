import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/protocol.dart';

/// Passive greeting only. No command, credentials or negotiation payload is sent.
Future<ProtocolObservation> inspectGreeting(String host, int port) async {
  Socket? socket;
  try {
    socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 2),
    );
    final bytes = await socket.first.timeout(const Duration(seconds: 1));
    final prefix = bytes.take(512).toList();
    final text = latin1
        .decode(prefix)
        .replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ')
        .trim();
    if (text.startsWith('SSH-')) {
      return ProtocolObservation(
        protocol: 'SSH',
        port: port,
        summary: 'banner.ssh',
        evidence: text,
      );
    }
    if (prefix.length >= 3 &&
        prefix[0] == 255 &&
        [251, 252, 253, 254].contains(prefix[1])) {
      return ProtocolObservation(
        protocol: 'Telnet',
        port: port,
        summary: 'banner.telnet',
        evidence: prefix
            .take(16)
            .map((n) => n.toRadixString(16).padLeft(2, '0'))
            .join(' '),
      );
    }
    if (text.startsWith('220') && text.toUpperCase().contains('FTP')) {
      return ProtocolObservation(
        protocol: 'FTP',
        port: port,
        summary: 'banner.ftp',
        evidence: text,
      );
    }
    return ProtocolObservation(
      protocol: 'TCP',
      port: port,
      summary: 'banner.unknown',
    );
  } catch (_) {
    return ProtocolObservation(
      protocol: 'TCP',
      port: port,
      summary: 'banner.unknown',
    );
  } finally {
    socket?.destroy();
  }
}
