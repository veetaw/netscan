import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:netscan/core/upnp.dart';
import 'package:netscan/scanner/protocol_native.dart';
import 'package:netscan/scanner/scanner_native.dart';
import 'package:netscan/scanner/upnp_native.dart';

void main() {
  test('device-provided URLs cannot pivot off the selected host', () {
    final base = Uri.parse('http://192.168.1.1/root.xml');
    for (final url in [
      'http://evil.example/control',
      '//10.0.0.2/control',
      'http://user@192.168.1.1/control',
      'file:///etc/passwd',
    ]) {
      expect(sameHostUri(url, '192.168.1.1', base: base), isNull);
    }
    expect(
      sameHostUri('/control', '192.168.1.1', base: base)!.path,
      '/control',
    );
  });
  test('real TCP connection succeeds and a closed listener fails', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    final sub = server.listen((socket) => socket.destroy());
    expect(await probeTcp('127.0.0.1', port), isTrue);
    await sub.cancel();
    await server.close();
    expect(await probeTcp('127.0.0.1', port), isFalse);
  });
  test(
    'RTSP verifies authentication without ever issuing PLAY or SETUP',
    () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final methods = <String>[];
      final sub = server.listen((socket) {
        socket.listen((data) {
          final method = utf8.decode(data).split(' ').first;
          methods.add(method);
          socket.write(
            method == 'OPTIONS'
                ? 'RTSP/1.0 200 OK\r\nCSeq: 1\r\nPublic: OPTIONS, DESCRIBE\r\n\r\n'
                : 'RTSP/1.0 401 Unauthorized\r\nCSeq: 1\r\n\r\n',
          );
          socket.close();
        });
      });
      try {
        final result = await inspectRtsp('127.0.0.1', server.port);
        expect(result.status, 401);
        expect(result.metadataWithoutAuth, isFalse);
        expect(methods, ['OPTIONS', 'DESCRIBE']);
      } finally {
        await sub.cancel();
        await server.close();
      }
    },
  );
  test(
    'SDP header is reported as metadata, never proof of video access',
    () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sub = server.listen((socket) {
        socket.listen((_) {
          socket.write(
            'RTSP/1.0 200 OK\r\nCSeq: 1\r\nContent-Type: application/sdp\r\n\r\n',
          );
          socket.close();
        });
      });
      try {
        final result = await inspectRtsp('127.0.0.1', server.port);
        expect(result.metadataWithoutAuth, isTrue);
        expect(result.summary, contains('Non è stata provata la visione'));
      } finally {
        await sub.cancel();
        await server.close();
      }
    },
  );
  test('ONVIF extracts product identity but discards serial numbers', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final sub = server.listen((request) async {
      expect(request.method, 'POST');
      expect(
        await utf8.decoder.bind(request).join(),
        contains('GetDeviceInformation'),
      );
      request.response.write(
        '<Envelope><GetDeviceInformationResponse>'
        '<Manufacturer>Example</Manufacturer><Model>Camera</Model><FirmwareVersion>1.2</FirmwareVersion>'
        '<SerialNumber>PRIVATE-SERIAL</SerialNumber></GetDeviceInformationResponse></Envelope>',
      );
      await request.response.close();
    });
    try {
      final result = await inspectOnvif('127.0.0.1', server.port);
      expect(result.identity!.model, 'Camera');
      expect(
        jsonEncode(result.identity!.toJson()),
        isNot(contains('PRIVATE-SERIAL')),
      );
    } finally {
      await sub.cancel();
      await server.close(force: true);
    }
  });
  test('UPnP mock gateway enumerates mappings using read-only actions', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final udp = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      1900,
    );
    final udpSub = udp.listen((event) {
      if (event != RawSocketEvent.read) return;
      final packet = udp.receive();
      if (packet == null) return;
      udp.send(
        utf8.encode(
          'HTTP/1.1 200 OK\r\nLOCATION: http://127.0.0.1:${server.port}/root.xml\r\n\r\n',
        ),
        packet.address,
        packet.port,
      );
    });
    var reads = 0;
    final sub = server.listen((request) async {
      if (request.method == 'GET') {
        request.response.write(
          '<root><device><serviceList><service>'
          '<serviceType>urn:schemas-upnp-org:service:WANIPConnection:1</serviceType>'
          '<controlURL>/control</controlURL></service></serviceList></device></root>',
        );
      } else {
        expect(
          request.headers.value('SOAPAction'),
          contains('#GetGenericPortMappingEntry'),
        );
        final body = await utf8.decoder.bind(request).join();
        expect(body, isNot(contains('AddPortMapping')));
        if (reads++ == 0) {
          request.response.write(
            '<Envelope><NewExternalPort>5554</NewExternalPort><NewProtocol>TCP</NewProtocol>'
            '<NewInternalClient>192.168.1.20</NewInternalClient><NewInternalPort>554</NewInternalPort><NewEnabled>1</NewEnabled></Envelope>',
          );
        } else {
          request.response.statusCode = 500;
          request.response.write(
            '<Envelope><errorCode>713</errorCode></Envelope>',
          );
        }
      }
      await request.response.close();
    });
    try {
      final result = await inspectUpnp('127.0.0.1');
      expect(result.detected, isTrue);
      expect(result.mappingListComplete, isTrue);
      expect(result.mappings.single.internalPort, '554');
      expect(reads, 2);
    } finally {
      await udpSub.cancel();
      udp.close();
      await sub.cancel();
      await server.close(force: true);
    }
  });
}
