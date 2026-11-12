class ProtocolObservation {
  const ProtocolObservation({
    required this.protocol,
    required this.port,
    required this.summary,
    this.status,
    this.metadataWithoutAuth = false,
  });
  final String protocol, summary;
  final int port;
  final int? status;
  final bool metadataWithoutAuth;
  Map<String, Object?> toJson() => {
    'protocol': protocol,
    'port': port,
    'status': status,
    'summary': summary,
    'metadataWithoutAuth': metadataWithoutAuth,
  };
}

class DeviceIdentity {
  const DeviceIdentity(this.manufacturer, this.model, this.firmware);
  final String manufacturer, model, firmware;
  Map<String, String> toJson() => {
    'manufacturer': manufacturer,
    'model': model,
    'firmware': firmware,
    'source': 'ONVIF GetDeviceInformation (self-reported)',
  };
}
