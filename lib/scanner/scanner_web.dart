import 'package:http/http.dart' as http;
import '../core/report.dart';

Future<ScanReport> inspectHost(String host, {bool https = true}) async {
  if (!isPrivateIPv4(host)) {
    throw ArgumentError('Indirizzo privato IPv4 richiesto.');
  }
  final client = http.Client();
  try {
    final response = await client
        .get(Uri(scheme: https ? 'https' : 'http', host: host))
        .timeout(const Duration(seconds: 6));
    return ScanReport(
      host: host,
      method: 'browser-http',
      httpStatus: response.statusCode,
      message:
          'Risposta HTTP leggibile. Conferma soltanto la risposta '
          'dell’indirizzo richiesto, non modello, firmware o sicurezza.',
    );
  } catch (_) {
    return ScanReport(
      host: host,
      method: 'browser-http',
      message:
          'Esito non determinabile dal browser. Possibili cause: CORS, '
          'permesso di rete locale, certificato, contenuto misto, timeout o '
          'dispositivo irraggiungibile. Non significa che il dispositivo sia assente.',
    );
  } finally {
    client.close();
  }
}
