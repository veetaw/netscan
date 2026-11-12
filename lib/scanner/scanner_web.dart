import 'package:http/http.dart' as http;
import '../core/report.dart';

Future<ScanReport> inspectHost(String host, {bool https = true}) async {
  if (!isPrivateIPv4(host)) {
    throw ArgumentError('Indirizzo privato IPv4 richiesto.');
  }
  final client = http.Client();
  try {
    final response = await client
        .head(Uri(scheme: https ? 'https' : 'http', host: host))
        .timeout(const Duration(seconds: 6));
    return ScanReport(
      host: host,
      completedAt: DateTime.now(),
      method: 'browser-http',
      httpStatus: response.statusCode,
      message: 'web.readable',
    );
  } catch (_) {
    return ScanReport(
      host: host,
      completedAt: DateTime.now(),
      method: 'browser-http',
      message: 'web.unknown',
    );
  } finally {
    client.close();
  }
}
