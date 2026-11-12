import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ScanForm extends StatelessWidget {
  const ScanForm({
    super.key,
    required this.host,
    required this.busy,
    required this.authorized,
    required this.https,
    required this.authorize,
    required this.setHttps,
    required this.scan,
  });
  final TextEditingController host;
  final bool busy, authorized, https;
  final void Function(bool) authorize, setHttps;
  final VoidCallback scan;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '1. Controlla un dispositivo',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      const Text(
        'Collegati al Wi-Fi della rete da controllare. Trovi gli IP nell’elenco dispositivi del router.',
      ),
      const SizedBox(height: 16),
      TextField(
        controller: host,
        enabled: !busy,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          value: https,
          onChanged: busy ? null : setHttps,
        ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: const Text('La rete è mia o ho il permesso di controllarla.'),
        value: authorized,
        onChanged: busy ? null : (v) => authorize(v ?? false),
      ),
      FilledButton.icon(
        onPressed: authorized && !busy ? scan : null,
        icon: const Icon(Icons.radar),
        label: Text(busy ? 'Controllo in corso…' : 'Controlla dispositivo'),
      ),
      if (busy)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: LinearProgressIndicator(),
        ),
      if (busy)
        const Text(
          'Sto verificando porte e protocolli compatibili. Può richiedere circa un minuto.',
        ),
    ],
  );
}
