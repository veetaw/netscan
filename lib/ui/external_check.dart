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
      setState(
        () => _error =
            'Inserisci l’IPv4 pubblico dedicato mostrato dal tuo router. '
            'Indirizzi privati, CGNAT e IPv6 non sono supportati in questa prova.',
      );
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
              : 'Prova non conclusa. Usa l’app mobile, controlla dati mobili e permessi e riprova.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: const Text('Controlla da fuori casa'),
    subtitle: const Text('App mobile + dati cellulari · verifica separata'),
    children: [
      const Text(
        '1. Nel router leggi l’IPv4 pubblico della connessione di casa. '
        'Se è condiviso dall’operatore (CGNAT), non eseguire questa prova. '
        '2. Sul telefono disattiva Wi-Fi e VPN e attiva i dati mobili. '
        '3. Inserisci l’indirizzo dedicato e avvia il controllo. '
        'Non servono account o server Netscan.',
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _address,
        enabled: !_busy,
        decoration: const InputDecoration(
          labelText: 'IPv4 pubblico della tua connessione',
        ),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Ho verificato che l’IP sia dedicato alla mia connessione, '
          'ho il permesso di controllarlo e ho disattivato Wi-Fi e VPN.',
        ),
        value: _authorized,
        onChanged: _busy
            ? null
            : (v) => setState(() => _authorized = v ?? false),
      ),
      FilledButton(
        onPressed: _authorized && !_busy ? _run : null,
        child: Text(
          _busy ? 'Prova esterna in corso…' : 'Controlla accessi esterni',
        ),
      ),
      if (_busy)
        const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
      if (_error != null) StatusText(_error!),
      if (_report != null) ...[
        ReportView(report: _report!),
        TextButton(
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
                const SnackBar(
                  content: Text('Report copiato: contiene il tuo IP pubblico.'),
                ),
              );
            }
          },
          child: const Text('Copia report della prova esterna'),
        ),
      ],
    ],
  );
}
