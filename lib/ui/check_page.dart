import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/report.dart';
import '../scanner/scanner.dart';
import 'advisory_panel.dart';
import 'external_check.dart';
import 'privacy_button.dart';
import 'report_view.dart';
import 'scan_form.dart';
import 'security_guide.dart';

class CheckPage extends StatefulWidget {
  const CheckPage({super.key});
  @override
  State<CheckPage> createState() => _CheckPageState();
}

class _CheckPageState extends State<CheckPage> {
  final _host = TextEditingController();
  final _model = TextEditingController();
  final _firmware = TextEditingController();
  final _confirmed = <String>{};
  bool _authorized = false, _https = true, _busy = false;
  ScanReport? _report;
  String? _error;
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
      setState(
        () => _error =
            'Inserisci un IP privato, per esempio 192.168.1.1. Lo trovi nell’elenco dispositivi del router.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _report = null;
    });
    try {
      final report = await inspectHost(host, https: _https);
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
      if (mounted) {
        setState(
          () => _error =
              'Controllo non riuscito. Verifica il permesso di rete locale e riprova.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(Uri uri) async {
    try {
      if (!await launchUrl(uri)) throw StateError('Link non aperto');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile aprire il link in questo dispositivo.'),
          ),
        );
      }
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent('  ').convert({
          ..._report!.toJson(),
          'model': _model.text.trim(),
          'firmware': _firmware.text.trim(),
          'userConfirmedChecks': _confirmed.toList(),
        }),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report copiato. Contiene indirizzi di rete: condividilo con attenzione.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('netscan'),
      actions: const [PrivacyButton()],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Conosci meglio la tua rete.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              kIsWeb
                  ? 'Controllo web leggero · nessuna installazione'
                  : 'Controllo locale · app installata',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Un dispositivo alla volta, con evidenze e passi pratici. '
              'Il PoC non rileva ogni vulnerabilità né certifica la sicurezza della rete.',
            ),
            const SizedBox(height: 32),
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
            if (_report != null) ReportView(report: _report!),
            AdvisoryPanel(model: _model, firmware: _firmware, open: _open),
            const SizedBox(height: 24),
            if (!kIsWeb) const ExternalCheck(),
            SecurityGuide(
              confirmed: _confirmed,
              onChanged: (id, value) => setState(() {
                if (value) {
                  _confirmed.add(id);
                } else {
                  _confirmed.remove(id);
                }
              }),
              open: _open,
            ),
            if (_report != null)
              TextButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy),
                label: const Text('Copia report locale'),
              ),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text(
                  'Per i controlli di protocolli, UPnP e accessi esterni usa l’app installata. '
                  'Il PoC è disponibile dal sorgente; i download pubblici non sono ancora pubblicati.',
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
