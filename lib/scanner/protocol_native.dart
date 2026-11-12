import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';
import '../core/protocol.dart';
import '../core/upnp.dart';

/// Stops at headers. Never issues SETUP/PLAY or receives a media stream.
Future<ProtocolObservation> inspectRtsp(String host, int port) async {
  final uri = 'rtsp://$host:$port/';
  Future<String> headers(String method) async {
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 2),
    );
    try {
      socket.write(
        '$method $uri RTSP/1.0\r\nCSeq: 1\r\n'
        'User-Agent: Netscan/0.1\r\nAccept: application/sdp\r\n\r\n',
      );
      final output = <int>[];
      return await (() async {
        await for (final chunk in socket) {
          if (output.length + chunk.length > 16384) {
            throw const FormatException('RTSP header too large');
          }
          output.addAll(chunk);
          final text = latin1.decode(output);
          final end = text.indexOf('\r\n\r\n');
          if (end >= 0) return text.substring(0, end);
        }
        throw const FormatException('Incomplete RTSP response');
      })().timeout(const Duration(seconds: 2));
    } finally {
      socket.destroy();
    }
  }

  try {
    final options = await headers('OPTIONS');
    if (!RegExp(r'^RTSP/1\.0 [0-9]{3}').hasMatch(options)) {
      return ProtocolObservation(
        protocol: 'RTSP',
        port: port,
        summary: 'Porta raggiungibile, protocollo RTSP non confermato.',
      );
    }
    final response = await headers('DESCRIBE');
    final match = RegExp(r'^RTSP/1\.0 ([0-9]{3})').firstMatch(response);
    final status = match == null ? null : int.parse(match[1]!);
    final metadata =
        status == 200 &&
        RegExp(
          r'^content-type:\s*application/sdp',
          caseSensitive: false,
          multiLine: true,
        ).hasMatch(response);
    return ProtocolObservation(
      protocol: 'RTSP',
      port: port,
      status: status,
      metadataWithoutAuth: metadata,
      summary: metadata
          ? 'Il percorso / risponde senza credenziali dichiarando metadati SDP. Verifica l’autenticazione della camera. Non è stata provata la visione del video.'
          : [401, 403].contains(status)
          ? 'Il percorso / richiede autenticazione o nega accesso. Questo non verifica gli altri percorsi o l’accesso cloud.'
          : 'RTSP confermato; accesso video non determinabile sul percorso /. Nessuna immagine acquisita.',
    );
  } catch (_) {
    return ProtocolObservation(
      protocol: 'RTSP',
      port: port,
      summary:
          'Verifica RTSP incompleta: timeout, protocollo differente o risposta non compatibile.',
    );
  }
}

Future<({ProtocolObservation observation, DeviceIdentity? identity})>
inspectOnvif(String host, int port) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  try {
    return await (() async {
      final request = await client.postUrl(
        Uri(
          scheme: 'http',
          host: host,
          port: port,
          path: '/onvif/device_service',
        ),
      );
      request.followRedirects = false;
      request.headers.contentType = ContentType(
        'application',
        'soap+xml',
        charset: 'utf-8',
      );
      request.write(
        '<?xml version="1.0"?><s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
        '<s:Body><tds:GetDeviceInformation xmlns:tds="http://www.onvif.org/ver10/device/wsdl"/>'
        '</s:Body></s:Envelope>',
      );
      final response = await request.close();
      final bytes = <int>[];
      await for (final chunk in response) {
        if (bytes.length + chunk.length > 65536) {
          throw const FormatException('Response too large');
        }
        bytes.addAll(chunk);
      }
      DeviceIdentity? identity;
      if (response.statusCode == 200) {
        final doc = XmlDocument.parse(utf8.decode(bytes));
        if (doc.descendants.whereType<XmlElement>().any(
          (e) => e.name.local == 'GetDeviceInformationResponse',
        )) {
          // Serial number and hardware identifiers intentionally not collected.
          identity = DeviceIdentity(
            xmlValue(doc, 'Manufacturer'),
            xmlValue(doc, 'Model'),
            xmlValue(doc, 'FirmwareVersion'),
          );
        }
      }
      return (
        observation: ProtocolObservation(
          protocol: 'ONVIF',
          port: port,
          status: response.statusCode,
          summary: identity != null
              ? 'Informazioni prodotto ONVIF ricevute. Sono dichiarazioni del dispositivo, da confermare sull’etichetta.'
              : [401, 403].contains(response.statusCode)
              ? 'Il percorso ONVIF richiede autenticazione o nega accesso; il servizio non è stato identificato con certezza.'
              : 'Nessuna identità ONVIF verificata sul percorso standard. Non esclude una camera o un percorso diverso.',
        ),
        identity: identity,
      );
    })().timeout(const Duration(seconds: 3));
  } catch (_) {
    return (
      observation: ProtocolObservation(
        protocol: 'ONVIF',
        port: port,
        summary: 'Verifica ONVIF sul percorso standard non conclusa.',
      ),
      identity: null,
    );
  } finally {
    client.close(force: true);
  }
}
