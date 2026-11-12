import 'dart:convert';
import 'package:http/http.dart' as http;

class ThreatContext {
  const ThreatContext({this.kev, this.epss, this.epssDate, this.kevDate});
  final bool? kev;
  final double? epss;
  final String? epssDate, kevDate;
}

Future<Map<String, ThreatContext>> fetchThreatContext(
  List<String> ids, {
  http.Client? client,
}) async {
  final unique = ids
      .toSet()
      .where((id) => RegExp(r'^CVE-[0-9]{4}-[0-9]{4,}$').hasMatch(id))
      .take(20)
      .toList();
  if (unique.isEmpty) return {};
  final transport = client ?? http.Client();
  Future<Map<String, dynamic>?> get(Uri uri) async {
    try {
      final response = await transport
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 ||
          response.bodyBytes.length > 8 * 1024 * 1024) {
        return null;
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  try {
    final feeds = await Future.wait([
      get(
        Uri.https(
          'raw.githubusercontent.com',
          '/cisagov/kev-data/main/known_exploited_vulnerabilities.json',
        ),
      ),
      get(
        Uri.https('api.first.org', '/data/v1/epss', {'cve': unique.join(',')}),
      ),
    ]);
    final kev = feeds[0], epss = feeds[1];
    var kevValid =
        kev?['vulnerabilities'] is List &&
        kev?['dateReleased'] is String &&
        (kev!['vulnerabilities'] as List).isNotEmpty;
    final known = kevValid
        ? (kev['vulnerabilities'] as List)
              .whereType<Map>()
              .map((v) => v['cveID'])
              .toSet()
        : <dynamic>{};
    if (known
        .whereType<String>()
        .where((id) => RegExp(r'^CVE-[0-9]{4}-[0-9]{4,}$').hasMatch(id))
        .isEmpty) {
      kevValid = false;
    }
    final probabilities = <String, Map>{};
    if (epss?['data'] is List) {
      for (final item in (epss!['data'] as List).whereType<Map>()) {
        if (item['cve'] is String) probabilities[item['cve'] as String] = item;
      }
    }
    return {
      for (final id in unique)
        id: ThreatContext(
          kev: kevValid ? known.contains(id) : null,
          kevDate: kevValid ? kev!['dateReleased'] as String : null,
          epss: _probability(probabilities[id]?['epss']),
          epssDate: probabilities[id]?['date'] is String
              ? probabilities[id]!['date'] as String
              : null,
        ),
    };
  } finally {
    if (client == null) transport.close();
  }
}

double? _probability(Object? value) {
  final parsed = double.tryParse('$value');
  return parsed != null && parsed.isFinite && parsed >= 0 && parsed <= 1
      ? parsed
      : null;
}
