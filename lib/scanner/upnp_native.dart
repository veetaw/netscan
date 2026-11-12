import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:xml/xml.dart';
import '../core/upnp.dart';

Future<Uri?> _discover(String host) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final result = Completer<Uri>();
  final listener = socket.listen((event) {
    if (event != RawSocketEvent.read) return;
    final packet = socket.receive();
    if (packet == null ||
        packet.address.address != host ||
        packet.data.length > 16384) {
      return;
    }
    final text = utf8.decode(packet.data, allowMalformed: true);
    if (!text.startsWith('HTTP/1.1 200')) return;
    for (final line in text.split('\r\n')) {
      if (!line.toLowerCase().startsWith('location:')) continue;
      final location = sameHostUri(line.substring(9).trim(), host);
      if (location != null && !result.isCompleted) result.complete(location);
    }
  });
  try {
    // A targeted unicast search, no multicast entitlement or network-wide sweep.
    socket.send(
      utf8.encode(
        'M-SEARCH * HTTP/1.1\r\nHOST: $host:1900\r\n'
        'MAN: "ssdp:discover"\r\nST: upnp:rootdevice\r\n\r\n',
      ),
      InternetAddress(host),
      1900,
    );
    return await result.future.timeout(
      const Duration(seconds: 2),
      onTimeout: () => throw TimeoutException('SSDP'),
    );
  } on TimeoutException {
    return null;
  } finally {
    await listener.cancel();
    socket.close();
  }
}

Future<({int status, String body})> _request(
  Uri uri, {
  String? soap,
  String? type,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
  try {
    return await (() async {
      final request = await client.openUrl(soap == null ? 'GET' : 'POST', uri);
      request.followRedirects = false;
      if (soap != null) {
        request.headers.contentType = ContentType(
          'text',
          'xml',
          charset: 'utf-8',
        );
        request.headers.set('SOAPAction', '"$type#GetGenericPortMappingEntry"');
        request.write(soap);
      }
      final response = await request.close();
      final bytes = <int>[];
      await for (final chunk in response) {
        if (bytes.length + chunk.length > 131072) {
          throw const FormatException('Response too large');
        }
        bytes.addAll(chunk);
      }
      return (
        status: response.statusCode,
        body: utf8.decode(bytes, allowMalformed: true),
      );
    })().timeout(const Duration(seconds: 3));
  } finally {
    client.close(force: true);
  }
}

Future<UpnpObservation> inspectUpnp(String host) async {
  var detected = false;
  final mappings = <PortMapping>[];
  try {
    final location = await _discover(host);
    if (location == null) {
      return const UpnpObservation(
        detected: false,
        message:
            'Nessuna risposta alla ricerca UPnP mirata. Non prova che UPnP sia disattivato: controlla le impostazioni del router.',
      );
    }
    detected = true;
    final description = await _request(location);
    if (description.status != 200) {
      throw const FormatException('Description unavailable');
    }
    final service = gatewayService(description.body, location, host);
    if (service == null) {
      return const UpnpObservation(
        detected: true,
        message:
            'Dispositivo UPnP rilevato; nessun servizio gateway compatibile trovato. UPnP non implica necessariamente inoltro porte.',
      );
    }
    for (var index = 0; index < 8; index++) {
      final response = await _request(
        service.control,
        type: service.type,
        soap:
            '<?xml version="1.0"?>'
            '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
            '<s:Body><u:GetGenericPortMappingEntry xmlns:u="${service.type}">'
            '<NewPortMappingIndex>$index</NewPortMappingIndex>'
            '</u:GetGenericPortMappingEntry></s:Body></s:Envelope>',
      );
      if (response.status != 200) {
        final code = xmlValue(XmlDocument.parse(response.body), 'errorCode');
        return UpnpObservation(
          detected: true,
          mappings: mappings,
          mappingListComplete: code == '713',
          message: code == '713'
              ? 'Letto l’elenco del servizio UPnP selezionato. Non include necessariamente regole manuali, DMZ, PCP/NAT-PMP o firewall IPv6.'
              : 'UPnP rilevato, ma elenco regole non completamente leggibile. Verifica il pannello del router.',
        );
      }
      mappings.add(parseMapping(response.body));
    }
    return UpnpObservation(
      detected: true,
      mappings: mappings,
      message:
          'Mostrate le prime otto regole UPnP del servizio selezionato. L’elenco può essere incompleto.',
    );
  } catch (_) {
    return UpnpObservation(
      detected: detected,
      mappings: mappings,
      message:
          'Verifica UPnP incompleta: servizio non compatibile, permessi o errore di rete. Nessuna configurazione è stata modificata.',
    );
  }
}
