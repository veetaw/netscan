import '../core/report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_selector/file_selector.dart';
import '../core/import_report.dart';
import '../discovery/discovery.dart';
import '../inventory/controller.dart';
import '../l10n/strings.dart';
import 'report_view.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    required this.inventory,
    required this.inspect,
  });
  final InventoryController inventory;
  final void Function(String) inspect;
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool _allowed = false, _busy = false;
  String? _message;
  Future<void> _discover() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await discoverDevices(widget.inventory.addDiscovery);
      widget.inventory.flush();
      if (mounted) setState(() => _message = 'discovery.done');
    } catch (_) {
      if (mounted) setState(() => _message = 'discovery.failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'Netscan / Nmap',
            extensions: ['json', 'xml'],
            uniformTypeIdentifiers: ['public.json', 'public.xml'],
          ),
        ],
      );
      if (file == null) return;
      if (await file.length() > 2 * 1024 * 1024) {
        throw const FormatException('File too large');
      }
      final reports = importReports(await file.readAsString());
      for (final report in reports) {
        widget.inventory.addReport(report, notify: false);
      }
      widget.inventory.flush();
      if (mounted) setState(() => _message = 'import.done');
    } catch (_) {
      if (mounted) setState(() => _message = 'import.error');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.inventory,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          tr(context, 'app.tagline'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(tr(context, 'inventory.intro')),
        const SizedBox(height: 16),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(tr(context, 'scan.authorize')),
          value: _allowed,
          onChanged: _busy
              ? null
              : (v) => setState(() => _allowed = v ?? false),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: !kIsWeb && _allowed && !_busy ? _discover : null,
              icon: const Icon(Icons.radar),
              label: Text(
                tr(context, _busy ? 'discovery.running' : 'discovery.run'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _import,
              icon: const Icon(Icons.file_open),
              label: Text(tr(context, 'import.run')),
            ),
            TextButton(
              onPressed: () => widget.inspect(''),
              child: Text(tr(context, 'inventory.manual')),
            ),
          ],
        ),
        if (kIsWeb) StatusText('discovery.web'),
        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: LinearProgressIndicator(),
          ),
        if (_message != null) StatusText(_message!),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: widget.inventory.persistent,
          title: Text(tr(context, 'inventory.persist')),
          subtitle: Text(tr(context, 'inventory.storagePrivacy')),
          onChanged: widget.inventory.setPersistent,
        ),
        if (widget.inventory.storageFailed)
          StatusText('inventory.storageError'),
        if (widget.inventory.devices.isEmpty) StatusText('inventory.empty'),
        for (final record in widget.inventory.devices.values)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(record.host),
                  if (record.advertisedServices.isNotEmpty)
                    Text(
                      '${tr(context, 'inventory.advertised')}: ${record.advertisedServices.join(', ')}',
                    ),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: record.group,
                    items: [
                      for (final group in [
                        'unknown',
                        'trusted',
                        'iot',
                        'guest',
                      ])
                        DropdownMenuItem(
                          value: group,
                          child: Text(tr(context, 'group.$group')),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        widget.inventory.setGroup(record.host, value);
                      }
                    },
                  ),
                  Text(tr(context, 'inventory.groupHint')),
                  if (record.history.isNotEmpty)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(tr(context, 'inventory.latest')),
                      children: [ReportView(report: record.history.first)],
                    ),
                  if (record.history.length > 1)
                    _DeltaView(record.history[1], record.history[0]),
                  TextButton.icon(
                    onPressed: () => widget.inspect(record.host),
                    icon: const Icon(Icons.manage_search),
                    label: Text(tr(context, 'scan.run')),
                  ),
                ],
              ),
            ),
          ),
        if (widget.inventory.devices.isNotEmpty)
          Wrap(
            spacing: 12,
            children: [
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: widget.inventory.export()),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr(context, 'scan.copied'))),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: Text(tr(context, 'inventory.export')),
              ),
              TextButton(
                onPressed: () async {
                  final clear = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(tr(context, 'inventory.clear')),
                      content: Text(tr(context, 'inventory.clearQuestion')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(tr(context, 'common.cancel')),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(tr(context, 'inventory.clear')),
                        ),
                      ],
                    ),
                  );
                  if (clear == true) await widget.inventory.clear();
                },
                child: Text(tr(context, 'inventory.clear')),
              ),
            ],
          ),
      ],
    ),
  );
}

class _DeltaView extends StatelessWidget {
  const _DeltaView(this.previous, this.current);
  final ScanReport previous, current;
  @override
  Widget build(BuildContext context) {
    try {
      final delta = compareReports(previous, current);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, 'delta.warning')),
          Text(
            tr(context, 'delta.opened', {
              'ports': delta.newlyReachable.isEmpty
                  ? '—'
                  : delta.newlyReachable.join(', '),
            }),
          ),
          Text(
            tr(context, 'delta.unreachable', {
              'ports': delta.noLongerReachable.isEmpty
                  ? '—'
                  : delta.noLongerReachable.join(', '),
            }),
          ),
        ],
      );
    } catch (_) {
      return Text(tr(context, 'delta.different'));
    }
  }
}
