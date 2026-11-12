import 'dart:async';
import 'package:flutter/material.dart';
import '../core/advisories.dart';
import 'report_view.dart';

class AdvisoryPanel extends StatefulWidget {
  const AdvisoryPanel({
    super.key,
    required this.model,
    required this.firmware,
    required this.open,
  });
  final TextEditingController model, firmware;
  final void Function(Uri) open;
  @override
  State<AdvisoryPanel> createState() => _AdvisoryPanelState();
}

class _AdvisoryPanelState extends State<AdvisoryPanel> {
  bool _allow = false, _busy = false;
  int _cooldown = 0;
  Timer? _timer;
  AdvisorySearch? _results;
  String? _error;
  String _query = '';
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _search() async {
    final query = widget.model.text.trim();
    if (query.length < 3) {
      setState(
        () => _error = 'Inserisci produttore e modello, almeno tre caratteri.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _results = null;
      _cooldown = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown == 0) timer.cancel();
    });
    try {
      final found = await searchAdvisories(query);
      if (mounted) {
        setState(() {
          _results = found;
          _query = query;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Ricerca non riuscita: NVD può essere indisponibile o limitare le richieste. Riprova più tardi.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 32),
      Text(
        '2. Cerca avvisi di sicurezza',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      const Text(
        'Leggi produttore e modello sull’etichetta; il firmware è solitamente nelle impostazioni. '
        'Se compilati via ONVIF, conferma i dati dichiarati dal dispositivo.',
      ),
      const SizedBox(height: 16),
      TextField(
        controller: widget.model,
        maxLength: 100,
        enabled: !_busy,
        decoration: const InputDecoration(labelText: 'Produttore e modello'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: widget.firmware,
        maxLength: 80,
        decoration: const InputDecoration(
          labelText: 'Firmware (facoltativo, resta sul dispositivo)',
        ),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text(
          'Invia produttore e modello a NVD per questa ricerca.',
        ),
        subtitle: const Text(
          'Servizio NIST negli USA: riceve il testo cercato e il tuo IP pubblico. '
          'Non inserire nomi, password o numeri di serie.',
        ),
        value: _allow,
        onChanged: _busy ? null : (v) => setState(() => _allow = v ?? false),
      ),
      OutlinedButton.icon(
        onPressed: _allow && !_busy && _cooldown == 0 ? _search : null,
        icon: const Icon(Icons.search),
        label: Text(
          _busy
              ? 'Ricerca in corso…'
              : _cooldown > 0
              ? 'Nuova ricerca tra $_cooldown s'
              : 'Cerca avvisi pubblici',
        ),
      ),
      if (_busy)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: LinearProgressIndicator(),
        ),
      if (_error != null) StatusText(_error!),
      if (_results != null) ...[
        const SizedBox(height: 16),
        Text(
          '${_results!.total} risultati per “$_query” · mostrati ${_results!.items.length}',
        ),
        const StatusText(
          'Abbinamenti per parole chiave, da verificare. '
          'Il firmware non è stato confrontato con le versioni vulnerabili. '
          'Zero risultati non significa assenza di vulnerabilità.',
        ),
        for (final item in _results!.items)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(item.id),
            subtitle: const Text('Possibile corrispondenza · non confermata'),
            children: [
              SelectableText(item.description),
              TextButton(
                onPressed: () => widget.open(item.url),
                child: const Text(
                  'Apri fonte NVD e riferimenti del produttore',
                ),
              ),
            ],
          ),
      ],
    ],
  );
}
