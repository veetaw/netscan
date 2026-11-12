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
      if (report.identity != null)
        StatusText(
          'Identità dichiarata via ONVIF: '
          '${report.identity!.manufacturer} ${report.identity!.model}, firmware ${report.identity!.firmware}. '
          'Conferma questi dati prima di cercare avvisi.',
        ),
      if (report.httpStatus != null) Text('Stato HTTP: ${report.httpStatus}'),
      if (report.upnp != null) ...[
        Text(
          'UPnP · ${report.upnp!.detected ? 'risposta ricevuta' : 'stato non confermato'}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        StatusText(report.upnp!.message),
        for (final m in report.upnp!.mappings)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.call_split),
            title: Text(
              '${m.protocol} ${m.externalPort} → ${m.internalClient}:${m.internalPort}',
            ),
            subtitle: Text(
              '${m.enabled ? 'Regola abilitata' : 'Regola disabilitata'} · '
              'Verifica che ti serva. Non dimostra raggiungibilità da Internet.',
            ),
          ),
      ],
      for (final p in report.protocols)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            p.metadataWithoutAuth ? Icons.priority_high : Icons.info_outline,
          ),
          title: Text('${p.protocol} sulla porta ${p.port}'),
          subtitle: Text(p.summary),
        ),
      for (final p in report.ports.where((p) => p.reachable))
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.link),
          title: Text('Porta ${p.port} raggiungibile'),
          subtitle: Text(_hint(p.port)),
        ),
      if (report.ports.any((p) => !p.reachable))
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Porte senza connessione riuscita'),
          subtitle: const Text(
            'Chiuse, filtrate, in timeout o bloccate dai permessi: stato non determinato.',
          ),
          children: [
            for (final p in report.ports.where((p) => !p.reachable))
              ListTile(
                title: Text('Porta ${p.port} · connessione non riuscita'),
              ),
          ],
        ),
    ],
  );

  String _hint(int port) => switch (port) {
    23 =>
      'Spesso usata da Telnet, che non cifra il traffico. Conferma il servizio e disattivalo se inutile.',
    21 =>
      'Spesso usata da FTP tradizionale. Verifica cifratura e necessità del servizio.',
    80 || 8080 =>
      'Possibile servizio HTTP. Non prova che sia il pannello del router o che sia pubblico.',
    443 || 8443 =>
      'Possibile servizio HTTPS. La porta da sola non verifica protocollo o certificato.',
    22 =>
      'Spesso usata da SSH. Limita l’amministrazione ai dispositivi fidati se il servizio è confermato.',
    445 =>
      'Possibile condivisione SMB. Verifica necessità, utenti e accessi consentiti.',
    3389 =>
      'Possibile desktop remoto. Verifica che serva e limita gli accessi.',
    554 || 8554 =>
      'Porta comunemente usata per streaming RTSP: vedi la verifica di protocollo.',
    _ =>
      'Servizio da identificare. Il numero della porta non identifica il produttore.',
  };
}
