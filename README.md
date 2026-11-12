# Netscan · PoC

App Flutter in italiano per controllare un dispositivo della propria rete e cercare avvisi di sicurezza pubblici. Mobile first, con versione web light e desktop.

## Avvio

Richiede Flutter (verificato con 3.44.4 / Dart 3.12.2).

```sh
flutter pub get
flutter run -d chrome
# oppure sul Mac
flutter run -d macos
# elenca smartphone ed emulatori disponibili
flutter devices
flutter run -d <device-id>
```

Su questo computer Flutter è in `/Users/vito/flutter/bin/flutter`.

## Funzioni reali

- App installata: connessioni TCP verso porte 80, 443, 22 e 23 di un IPv4 privato indicato dall’utente, massimo due secondi per porta. Nessun payload di exploit o tentativo di autenticazione.
- Web: richiesta HTTP/HTTPS verso l’IP esplicito. CORS, certificati e permessi possono rendere l’esito inconcludente: non viene dichiarato assente il dispositivo.
- Ricerca live NVD per produttore/modello, previa scelta esplicita; mostra fino a dieci CVE candidate e link alle fonti. Il firmware non viene inviato né confrontato automaticamente.
- Report JSON copiabile negli appunti; nessuna persistenza applicativa, analytics, account o backend.
- Nessuna richiesta LAN o NVD al caricamento della pagina.

La porta aperta non identifica il protocollo; una CVE trovata per parole chiave non conferma vulnerabilità. Un report senza risultati non certifica sicurezza. Il controllo LAN non prova esposizione WAN.

## Verifica

```sh
flutter analyze
flutter test
flutter build web
```

Test automatici: limiti degli indirizzi, parsing e query NVD, gestione rate limit, assenza di verdetti indebiti e layout a 320/768/1024/1440 px. La verifica live NVD è separata dai test riproducibili. La compatibilità mobile richiede prove su dispositivi reali e permessi concessi/negati.

## Distribuzione

Il sorgente è un PoC, non una release pubblica approvata. Nessun link a download inesistenti. Prima della distribuzione: firma dei pacchetti, identità e informativa del distributore, valutazione trasferimenti/dati/hosting, licenza del progetto, licenze dipendenze e verifica degli obblighi pertinenti. Vedi [documento UE](docs/eu-readiness.md).

## Prossime funzionalità

Discovery nativa tramite servizi dichiarati Bonjour/NSD, inventario, import report, fingerprint con evidenze, matching esatto modello/revisione/firmware con advisory ufficiali, KEV/EPSS, indicazioni specifiche per modello e collegamento web→app. Non sono implementate nel PoC corrente.
