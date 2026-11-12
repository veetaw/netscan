import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/report.dart';
import '../scanner/scanner.dart';
import '../l10n/strings.dart';
import 'advisory_panel.dart';
import 'external_check.dart';
import 'report_view.dart';
import 'scan_form.dart';

class CheckPage extends StatefulWidget {
  const CheckPage({super.key, this.initialHost = '', this.onReport});
  final String initialHost;
  final ValueChanged<ScanReport>? onReport;
  @override
  State<CheckPage> createState() => _CheckPageState();
}

class _CheckPageState extends State<CheckPage> {
  late final TextEditingController _host;
  final _model = TextEditingController(), _firmware = TextEditingController();
  bool _authorized = false, _https = true, _busy = false;
  ScanReport? _report;
  String? _error;
  @override
  void initState() {
    super.initState();
    _host = TextEditingController(text: widget.initialHost);
  }

  @override
  void dispose() {
    _host.dispose();
    _model.dispose();
    _firmware.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final host = _host.text.trim();
    if (!isPrivateIPv4(host)) {
      setState(() => _error = 'scan.invalidIP');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _report = null;
    });
    try {
      final report = await inspectHost(host, https: _https);
      widget.onReport?.call(report);
      if (mounted) {
        setState(() {
          _report = report;
          final identity = report.identity;
          if (identity != null && _model.text.trim().isEmpty) {
            _model.text = '${identity.manufacturer} ${identity.model}'.trim();
            _firmware.text = identity.firmware;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'scan.error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Uri uri) async {
    try {
      if (!await launchUrl(uri)) throw StateError('Failed');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr(context, 'link.error'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        tr(context, kIsWeb ? 'app.web' : 'app.local'),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      Text(tr(context, 'app.intro')),
      const SizedBox(height: 24),
      ScanForm(
        host: _host,
        busy: _busy,
        authorized: _authorized,
        https: _https,
        authorize: (v) => setState(() => _authorized = v),
        setHttps: (v) => setState(() => _https = v),
        scan: _scan,
      ),
      if (_error != null) StatusText(_error!),
      if (_report != null) ...[
        ReportView(report: _report!),
        TextButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(
                text: const JsonEncoder.withIndent(
                  '  ',
                ).convert(_report!.toJson()),
              ),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr(context, 'scan.copied'))),
              );
            }
          },
          icon: const Icon(Icons.copy),
          label: Text(tr(context, 'scan.copy')),
        ),
      ],
      AdvisoryPanel(model: _model, firmware: _firmware, open: _open),
      const SizedBox(height: 24),
      if (!kIsWeb) const ExternalCheck(),
      if (kIsWeb) ...[
        StatusText('web.install'),
        FilledButton(
          onPressed: () {
            if (!isPrivateIPv4(_host.text.trim())) {
              setState(() => _error = 'scan.invalidIP');
              return;
            }
            _open(
              Uri(
                scheme: 'netscan',
                host: 'inspect',
                queryParameters: {'host': _host.text.trim()},
              ),
            );
          },
          child: Text(tr(context, 'web.openApp')),
        ),
        TextButton(
          onPressed: () => _open(
            Uri.https(
              'github.com',
              '/veetaw/netscan/actions/workflows/build-release.yml',
            ),
          ),
          child: Text(tr(context, 'web.download')),
        ),
        StatusText('web.openHint'),
      ],
    ],
  );
}
