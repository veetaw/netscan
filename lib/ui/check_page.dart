import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/advisories.dart';
import '../core/report.dart';
import '../scanner/scanner.dart';
import 'report_view.dart';

class CheckPage extends StatefulWidget {
  const CheckPage({super.key});
  @override
  State<CheckPage> createState() => _CheckPageState();
}

class _CheckPageState extends State<CheckPage> {
  final _host = TextEditingController();
  final _model = TextEditingController();
  final _firmware = TextEditingController();
  bool _authorized = false, _external = false, _https = true;
  bool _scanning = false, _searching = false;
  ScanReport? _report;
  AdvisorySearch? _advisories;
  String? _scanError, _searchError;
  String _searchedModel = '';

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
        () => _scanError =
            'Inserisci un IP privato, per esempio 192.168.1.1. Lo trovi nell’elenco dispositivi del router.',
      );
      return;
    }
    setState(() {
      _scanning = true;
      _scanError = null;
      _report = null;
    });
    try {
      final report = await inspectHost(host, https: _https);
      if (mounted) setState(() => _report = report);
    } catch (_) {
      if (mounted)
        setState(
          () => _scanError =
              'Controllo non riuscito. Verifica il permesso di rete locale e riprova.',
        );
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _search() async {
    final model = _model.text.trim();
    setState(() {
      _searching = true;
      _searchError = null;
      _advisories = null;
    });
    try {
      final found = await searchAdvisories(model);
      if (mounted)
        setState(() {
          _advisories = found;
          _searchedModel = model;
        });
    } catch (_) {
      if (mounted)
        setState(
          () => _searchError =
              'Ricerca non riuscita. Verifica produttore e modello; NVD può essere temporaneamente indisponibile o limitare le richieste. Riprova tra almeno 30 secondi.',
        );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _open(Uri uri) async {
    try {
      if (!await launchUrl(uri)) throw StateError('Link non aperto');
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossibile aprire il link in questo dispositivo.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('netscan'),
      actions: [
        TextButton(
          onPressed: () => showAboutDialog(
            context: context,
            applicationName: 'Netscan',
            applicationVersion: '0.1.0 · PoC',
            children: const [
              Text(
                'I controlli restano in memoria fino alla chiusura. Nessuna telemetria o account. '
                'La ricerca NVD invia il testo del prodotto a NIST negli USA, che riceve anche il tuo IP pubblico. '
                'I link esterni sono soggetti alle informative dei rispettivi siti. '
                'Nessun risultato certifica la sicurezza del dispositivo.',
              ),
            ],
          ),
          child: const Text('Privacy'),
        ),
      ],
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
              'Un dispositivo alla volta, con indicazioni comprensibili. '
              'Questa prima versione non identifica automaticamente modello e firmware.',
            ),
            const SizedBox(height: 32),
            Text(
              '1. Controlla un dispositivo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _host,
              enabled: !_scanning,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Indirizzo IP locale',
                hintText: '192.168.1.1',
              ),
            ),
            if (kIsWeb)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Usa HTTPS'),
                subtitle: const Text(
                  'Il browser può bloccare HTTP e certificati non validi.',
                ),
                value: _https,
                onChanged: _scanning ? null : (v) => setState(() => _https = v),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'La rete è mia o ho il permesso di controllarla.',
              ),
              value: _authorized,
              onChanged: _scanning
                  ? null
                  : (v) => setState(() => _authorized = v ?? false),
            ),
            FilledButton.icon(
              onPressed: _authorized && !_scanning ? _scan : null,
              icon: const Icon(Icons.radar),
              label: Text(
                _scanning ? 'Controllo in corso…' : 'Controlla dispositivo',
              ),
            ),
            if (_scanning)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: LinearProgressIndicator(),
              ),
            if (_scanError != null) StatusText(_scanError!),
            if (_report != null) ReportView(report: _report!),
            const SizedBox(height: 32),
            Text(
              '2. Cerca avvisi di sicurezza',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const Text(
              'Leggi produttore e modello sull’etichetta; il firmware è solitamente nelle impostazioni del dispositivo.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _model,
              maxLength: 100,
              enabled: !_searching,
              decoration: const InputDecoration(
                labelText: 'Produttore e modello',
                hintText: 'Per esempio: marca e modello del router',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _firmware,
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
                'Servizio NIST negli USA: riceve il testo cercato e il tuo IP pubblico. Non inserire nomi, password o numeri di serie.',
              ),
              value: _external,
              onChanged: _searching
                  ? null
                  : (v) => setState(() => _external = v ?? false),
            ),
            OutlinedButton.icon(
              onPressed: _external && !_searching ? _search : null,
              icon: const Icon(Icons.search),
              label: Text(
                _searching ? 'Ricerca in corso…' : 'Cerca avvisi pubblici',
              ),
            ),
            if (_searching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: LinearProgressIndicator(),
              ),
            if (_searchError != null) StatusText(_searchError!),
            if (_advisories != null) ...[
              const SizedBox(height: 16),
              Text(
                '${_advisories!.total} risultati per “$_searchedModel” · mostrati ${_advisories!.items.length}',
              ),
              const StatusText(
                'Abbinamenti per parole chiave, da verificare. '
                'Non abbiamo confrontato il firmware con le versioni vulnerabili. '
                'Zero risultati non significa assenza di vulnerabilità.',
              ),
              for (final item in _advisories!.items)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(item.id),
                  subtitle: const Text(
                    'Possibile corrispondenza · non confermata',
                  ),
                  children: [
                    SelectableText(item.description),
                    TextButton(
                      onPressed: () => _open(item.url),
                      child: const Text(
                        'Apri fonte NVD e riferimenti del produttore',
                      ),
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Come muoverti',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Confronta modello, revisione hardware e firmware con l’avviso ufficiale. '
              'Se applicabile, segui le istruzioni di aggiornamento del produttore. '
              'Non installare firmware destinati a un modello diverso. '
              'Se il dispositivo non è più supportato, valuta sostituzione o isolamento in una rete ospiti.',
            ),
            if (_report != null)
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text: const JsonEncoder.withIndent('  ').convert({
                        ..._report!.toJson(),
                        'model': _model.text.trim(),
                        'firmware': _firmware.text.trim(),
                      }),
                    ),
                  );
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Report copiato. Contiene l’IP locale: condividilo con attenzione.',
                        ),
                      ),
                    );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copia report locale'),
              ),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text(
                  'Vuoi un controllo più completo? La versione installata può verificare connessioni TCP. '
                  'Il PoC è disponibile dal sorgente; i download pubblici non sono ancora pubblicati.',
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
