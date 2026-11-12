import 'package:flutter/material.dart';
import '../l10n/strings.dart';
import '../core/report.dart';

class StatusText extends StatelessWidget {
  const StatusText(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Semantics(liveRegion: true, child: Text(tr(context, text))),
  );
}

class ReportView extends StatelessWidget {
  const ReportView({super.key, required this.report});
  final ScanReport report;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(report.host, style: Theme.of(context).textTheme.titleLarge),
      if (report.imported) const StatusText('import.untrusted'),
      StatusText(report.message),
      if (report.identity != null)
        StatusText(
          tr(context, 'report.identity', {
            'vendor': report.identity!.manufacturer,
            'model': report.identity!.model,
            'firmware': report.identity!.firmware,
          }),
        ),
      if (report.httpStatus != null)
        Text(tr(context, 'report.http', {'status': report.httpStatus})),
      if (report.upnp != null) ...[
        Text(
          tr(
            context,
            report.upnp!.detected ? 'report.upnpYes' : 'report.upnpUnknown',
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        StatusText(report.upnp!.message),
        for (final m in report.upnp!.mappings)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.call_split),
            title: Text(
              tr(context, 'report.mapping', {
                'protocol': m.protocol,
                'external': m.externalPort,
                'host': m.internalClient,
                'internal': m.internalPort,
              }),
            ),
            subtitle: Text(
              tr(context, m.enabled ? 'report.mappingOn' : 'report.mappingOff'),
            ),
          ),
      ],
      for (final p in report.protocols)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            p.metadataWithoutAuth ? Icons.priority_high : Icons.info_outline,
          ),
          title: Text(
            tr(context, 'report.protocol', {
              'protocol': p.protocol,
              'port': p.port,
            }),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(context, p.summary)),
              if (p.evidence != null) SelectableText(p.evidence!),
            ],
          ),
        ),
      for (final p in report.ports.where((p) => p.reachable))
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.link),
          title: Text(tr(context, 'report.reachable', {'port': p.port})),
          subtitle: Text(tr(context, _hint(p.port))),
        ),
      if (report.ports.any((p) => !p.reachable))
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(tr(context, 'report.noConnection')),
          subtitle: Text(tr(context, 'report.unknown')),
          children: [
            for (final p in report.ports.where((p) => !p.reachable))
              ListTile(
                title: Text(
                  tr(context, 'report.portUnknown', {'port': p.port}),
                ),
              ),
          ],
        ),
    ],
  );
  String _hint(int port) => switch (port) {
    23 => 'hint.telnet',
    21 => 'hint.ftp',
    80 || 8080 => 'hint.http',
    443 || 8443 => 'hint.https',
    22 => 'hint.ssh',
    445 => 'hint.smb',
    3389 => 'hint.rdp',
    554 || 8554 => 'hint.rtsp',
    _ => 'hint.other',
  };
}
