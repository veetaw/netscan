import 'dart:convert';
import 'package:http/http.dart' as http;

class Advisory {
  const Advisory(this.id, this.description);
  final String id;
  final String description;
  Uri get url => Uri.https('nvd.nist.gov', '/vuln/detail/$id');
}

class AdvisorySearch {
  const AdvisorySearch(this.items, this.total);
  final List<Advisory> items;
  final int total;
}

Future<AdvisorySearch> searchAdvisories(
  String model, {
  http.Client? client,
}) async {
  final query = model.trim();
  if (query.length < 3 || query.length > 100) {
    throw ArgumentError('Inserisci produttore e modello (3–100 caratteri).');
  }
  final transport = client ?? http.Client();
  try {
    final response = await transport
        .get(
          Uri.https('services.nvd.nist.gov', '/rest/json/cves/2.0', {
            'keywordSearch': query,
            'resultsPerPage': '10',
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError(
        'Servizio NVD non disponibile (${response.statusCode}). Riprova più tardi.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = <Advisory>[];
    for (final entry in data['vulnerabilities'] as List<dynamic>) {
      final cve =
          (entry as Map<String, dynamic>)['cve'] as Map<String, dynamic>;
      final id = cve['id'] as String;
      if (!RegExp(r'^CVE-[0-9]{4}-[0-9]{4,}$').hasMatch(id)) continue;
      final descriptions = (cve['descriptions'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final english = descriptions.where((d) => d['lang'] == 'en');
      items.add(
        Advisory(
          id,
          english.isEmpty
              ? 'Descrizione non disponibile.'
              : english.first['value'] as String,
        ),
      );
    }
    return AdvisorySearch(items, data['totalResults'] as int);
  } finally {
    if (client == null) transport.close();
  }
}
