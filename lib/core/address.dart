int? ipv4Number(String value) {
  final parts = value.split('.');
  if (parts.length != 4) return null;
  var result = 0;
  for (final part in parts) {
    if (!RegExp(r'^(0|[1-9][0-9]{0,2})$').hasMatch(part)) return null;
    final n = int.parse(part);
    if (n > 255) return null;
    result = (result << 8) | n;
  }
  return result;
}

bool isPublicIPv4(String value) {
  final ip = ipv4Number(value);
  if (ip == null) return false;
  const excluded = [
    (0x00000000, 8),
    (0x0a000000, 8),
    (0x64400000, 10),
    (0x7f000000, 8),
    (0xa9fe0000, 16),
    (0xac100000, 12),
    (0xc0000000, 24),
    (0xc0000200, 24),
    (0xc0586300, 24),
    (0xc0a80000, 16),
    (0xc6120000, 15),
    (0xc6336400, 24),
    (0xcb007100, 24),
    (0xe0000000, 3),
  ];
  for (final block in excluded) {
    final shift = 32 - block.$2;
    if (ip >> shift == block.$1 >> shift) return false;
  }
  return true;
}
