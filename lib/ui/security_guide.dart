import '../l10n/strings.dart';
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
      SizedBox(height: 32),
      Text(
        tr(context, 'guide.title'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      SizedBox(height: 12),
      Text(tr(context, 'guide.instructions')),
      for (final step in hardeningSteps)
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(tr(context, step.title)),
          subtitle: Text(
            confirmed.contains(step.id)
                ? tr(context, 'guide.confirmed')
                : tr(context, 'guide.todo'),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr(context, step.why),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 12),
            Text(tr(context, step.action)),
            SizedBox(height: 12),
            Text('${tr(context, 'guide.verify')}: ${tr(context, step.verify)}'),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr(context, 'guide.checked')),
              value: confirmed.contains(step.id),
              onChanged: (v) => onChanged(step.id, v ?? false),
            ),
            TextButton(
              onPressed: () => open(Uri.parse(step.source)),
              child: Text(tr(context, 'guide.source')),
            ),
          ],
        ),
    ],
  );
}
