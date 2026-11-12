import 'package:xml/xml.dart';

class PortMapping {
  const PortMapping({
    required this.externalPort,
    required this.protocol,
    required this.internalClient,
    required this.internalPort,
    required this.enabled,
  });
  final String externalPort, protocol, internalClient, internalPort;
  final bool enabled;
  Map<String, Object> toJson() => {
    'externalPort': externalPort,
    'protocol': protocol,
    'internalClient': internalClient,
    'internalPort': internalPort,
    'enabled': enabled,
  };
}

class UpnpObservation {
  const UpnpObservation({
    required this.detected,
    required this.message,
    this.mappings = const [],
    this.mappingListComplete = false,
  });
  final bool detected, mappingListComplete;
  final String message;
  final List<PortMapping> mappings;
  Map<String, Object> toJson() => {
    'detected': detected,
    'message': message,
    'mappingListComplete': mappingListComplete,
    'mappings': [for (final m in mappings) m.toJson()],
  };
}

/// Never follow a device-provided URL away from the explicitly selected host.
Uri? sameHostUri(String value, String host, {Uri? base}) {
  final uri = base == null ? Uri.tryParse(value) : base.resolve(value);
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host != host ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    return null;
  }
  return uri;
}

String xmlValue(XmlNode node, String name) =>
    node.descendants
        .whereType<XmlElement>()
        .where((e) => e.name.local == name)
        .map((e) => e.innerText)
        .firstOrNull ??
    '';

class GatewayService {
  const GatewayService(this.type, this.control);
  final String type;
  final Uri control;
}

GatewayService? gatewayService(String body, Uri description, String host) {
  final doc = XmlDocument.parse(body);
  final baseText = xmlValue(doc, 'URLBase');
  final base = baseText.isEmpty ? description : sameHostUri(baseText, host);
  if (base == null) return null;
  for (final service in doc.descendants.whereType<XmlElement>().where(
    (e) => e.name.local == 'service',
  )) {
    final type = xmlValue(service, 'serviceType');
    if (!RegExp(
      r'^urn:schemas-upnp-org:service:WAN(IP|PPP)Connection:[12]$',
    ).hasMatch(type)) {
      continue;
    }
    final control = sameHostUri(
      xmlValue(service, 'controlURL'),
      host,
      base: base,
    );
    if (control != null) return GatewayService(type, control);
  }
  return null;
}

PortMapping parseMapping(String body) {
  final doc = XmlDocument.parse(body);
  final external = xmlValue(doc, 'NewExternalPort');
  final internal = xmlValue(doc, 'NewInternalPort');
  final protocol = xmlValue(doc, 'NewProtocol');
  if (int.tryParse(external) == null ||
      int.tryParse(internal) == null ||
      !['TCP', 'UDP'].contains(protocol)) {
    throw const FormatException('Invalid mapping');
  }
  return PortMapping(
    externalPort: external,
    protocol: protocol,
    internalClient: xmlValue(doc, 'NewInternalClient'),
    internalPort: internal,
    enabled: xmlValue(doc, 'NewEnabled') == '1',
  );
}
