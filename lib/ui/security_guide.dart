import 'package:flutter/material.dart';
import '../core/hardening.dart';

class SecurityGuide extends StatelessWidget {
  const SecurityGuide({
    super.key,
    required this.confirmed,
    required this.onChanged,
    required this.open,
  });
  final Set<String> confirmed;
  final void Function(String, bool) onChanged;
  final void Function(Uri) open;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 32),
      Text(
        '3. Proteggi la rete, un passo alla volta',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      const Text(
        'Controlli guidati nelle impostazioni. Le conferme qui sotto sono tue dichiarazioni, '
        'non verifiche automatiche o certificazioni. Restano solo in questa sessione.',
      ),
      for (final step in hardeningSteps)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(step.title),
          subtitle: Text(
            confirmed.contains(step.id)
                ? 'Confermato da te'
                : 'Da verificare nelle impostazioni',
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                step.why,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Text(step.action),
            const SizedBox(height: 12),
            Text('Come verificare: ${step.verify}'),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ho verificato questa impostazione'),
              value: confirmed.contains(step.id),
              onChanged: (v) => onChanged(step.id, v ?? false),
            ),
            TextButton(
              onPressed: () => open(Uri.parse(step.source)),
              child: const Text('Leggi la fonte'),
            ),
          ],
        ),
    ],
  );
}
