import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../core/address.dart';
import '../core/report.dart';
import '../scanner/external.dart';
import 'report_view.dart';

class ExternalCheck extends StatefulWidget {
  const ExternalCheck({super.key});
  @override
  State<ExternalCheck> createState() => _ExternalCheckState();
}

class _ExternalCheckState extends State<ExternalCheck> {
  final _address = TextEditingController();
  bool _authorized = false, _busy = false;
  String? _error;
  ScanReport? _report;
  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final host = _address.text.trim();
    if (!isPublicIPv4(host)) {
      setState(() => _error = 'external.invalid');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _report = null;
    });
    try {
      final result = await inspectExternal(host);
      if (mounted) setState(() => _report = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is StateError
              ? e.message.toString()
              : 'external.error',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: Text(tr(context, 'external.title')),
    subtitle: Text(tr(context, 'external.subtitle')),
    children: [
      Text(tr(context, 'external.instructions')),
      SizedBox(height: 16),
      TextField(
        controller: _address,
        enabled: !_busy,
        decoration: InputDecoration(labelText: tr(context, 'external.address')),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(tr(context, 'external.authorize')),
        value: _authorized,
        onChanged: _busy
            ? null
            : (v) => setState(() => _authorized = v ?? false),
      ),
      FilledButton(
        onPressed: _authorized && !_busy ? _run : null,
        child: Text(
          _busy ? tr(context, 'external.running') : tr(context, 'external.run'),
        ),
      ),
      if (_busy)
        Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
      if (_error != null) StatusText(_error!),
      if (_report != null) ...[
        ReportView(report: _report!),
        TextButton(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(
                text: JsonEncoder.withIndent('  ').convert(_report!.toJson()),
              ),
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr(context, 'external.copied'))),
              );
            }
          },
          child: Text(tr(context, 'external.copy')),
        ),
      ],
    ],
  );
}
