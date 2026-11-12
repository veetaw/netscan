import 'package:flutter/material.dart';
import '../core/report.dart';

class StatusText extends StatelessWidget {
  const StatusText(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Semantics(liveRegion: true, child: Text(text)),
  );
}

class ReportView extends StatelessWidget {
  const ReportView({super.key, required this.report});
  final ScanReport report;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      StatusText('${report.host}: ${report.message}'),
      if (report.httpStatus != null) Text('Stato HTTP: ${report.httpStatus}'),
      for (final p in report.ports)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(p.reachable ? Icons.link : Icons.help_outline),
          title: Text(
            'Porta ${p.port} · ${p.reachable ? 'raggiungibile' : 'connessione non riuscita'}',
          ),
          subtitle: Text(
            p.reachable
                ? 'Servizio e versione da identificare.'
                : 'Potrebbe essere chiusa, filtrata o bloccata dai permessi.',
          ),
        ),
      if (report.ports.any((p) => p.port == 23 && p.reachable))
        const StatusText(
          'La porta 23 è raggiungibile ed è spesso usata da Telnet. '
          'Se nelle impostazioni trovi Telnet attivo e non ti serve, disattivalo. '
          'Il protocollo non è stato verificato.',
        ),
    ],
  );
}
