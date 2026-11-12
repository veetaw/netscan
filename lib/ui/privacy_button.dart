import 'package:flutter/material.dart';
import '../l10n/strings.dart';

class PrivacyButton extends StatelessWidget {
  const PrivacyButton({super.key});
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => showAboutDialog(
      context: context,
      applicationName: 'Netscan',
      applicationVersion: '1.0.0',
      children: [Text(tr(context, 'privacy.body'))],
    ),
    child: Text(tr(context, 'privacy.title')),
  );
}
