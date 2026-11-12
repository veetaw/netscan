import 'package:flutter/material.dart';

class PrivacyButton extends StatelessWidget {
  const PrivacyButton({super.key});
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => showAboutDialog(
      context: context,
      applicationName: 'Netscan',
      applicationVersion: '0.1.0 · PoC',
      children: const [
        Text(
          'Controlli e conferme restano in memoria fino alla chiusura. Nessuna telemetria o account. '
          'I report copiati negli appunti possono essere sincronizzati dal sistema operativo. '
          'La ricerca NVD invia il testo del prodotto a NIST negli USA, che riceve anche il tuo IP pubblico. '
          'I link esterni seguono le informative dei rispettivi siti. '
          'Nessun risultato certifica la sicurezza del dispositivo.',
        ),
      ],
    ),
    child: const Text('Privacy'),
  );
}
