import '../l10n/strings.dart';
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
        tr(context, 'scan.title'),
        style: Theme.of(context).textTheme.titleLarge,
      ),
      SizedBox(height: 12),
      Text(tr(context, 'scan.instructions')),
      SizedBox(height: 16),
      TextField(
        controller: host,
        enabled: !busy,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: tr(context, 'scan.host'),
          hintText: '192.168.1.1',
        ),
      ),
      if (kIsWeb)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr(context, 'scan.https')),
          subtitle: Text(tr(context, 'scan.browserLimit')),
          value: https,
          onChanged: busy ? null : setHttps,
        ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(tr(context, 'scan.authorize')),
        value: authorized,
        onChanged: busy ? null : (v) => authorize(v ?? false),
      ),
      FilledButton.icon(
        onPressed: authorized && !busy ? scan : null,
        icon: Icon(Icons.radar),
        label: Text(
          busy ? tr(context, 'scan.running') : tr(context, 'scan.run'),
        ),
      ),
      if (busy)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: LinearProgressIndicator(),
        ),
      if (busy) Text(tr(context, 'scan.wait')),
    ],
  );
}
