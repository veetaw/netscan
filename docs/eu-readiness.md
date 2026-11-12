# Preparazione alla distribuzione UE

Stato al 12 novembre 2026: misure tecniche iniziali, **nessuna dichiarazione di conformità completa o certificazione**. Gli obblighi vanno valutati sulla concreta versione distribuita, sul ruolo del distributore e sul modello commerciale. Questo documento non sostituisce una valutazione legale.

## Misure presenti

- Scelta esplicita dell’utente prima del controllo LAN e della consultazione NVD. La dichiarazione di autorizzazione serve a delimitare l’uso, non è una prova di titolarità della rete né una base giuridica universale GDPR.
- Un solo IP RFC1918 esplicito, nessuna risoluzione DNS o scansione di indirizzi pubblici, nessun exploit e nessun tentativo di credenziali.
- Inventario e firmware non inviati a un server applicativo. Risultati in memoria, eliminati con la chiusura; gli appunti e i report copiati sono gestiti dal sistema operativo e possono essere sincronizzati dal dispositivo dell’utente.
- NVD riceve produttore/modello inseriti e l’IP pubblico della connessione. NIST è negli USA; nessun invio prima della richiesta dell’utente. Non si può descrivere il prodotto come “nessun dato lascia il dispositivo”.
- Nessun sistema di pubblicità o analytics, font e risorse applicative inclusi nella build. Il sito che ospiterà la build potrà comunque avere log: hosting e retention sono ancora da scegliere.
- Risultati spiegati come evidenze limitate, senza dichiarazioni di sicurezza o compromissione non supportate. Errori di rete e rate limit non sono interpretati come assenza di CVE.
- Permessi locali iOS/macOS e rete client macOS dichiarati; gestione Android del permesso runtime sulle versioni che lo richiedono. Discovery multicast non implementata e nessuna entitlement multicast richiesta.

## Decisioni prima di un rilascio pubblico

1. Identificare titolare, eventuali responsabili, finalità e basi giuridiche per ogni trattamento soggetto al GDPR. Definire informativa, contatti, diritti, retention, registro e procedure di sicurezza ove applicabili. La scelta NVD nella UI non risolve da sola i requisiti dei trasferimenti internazionali.
2. Valutare il trasferimento a NIST e i metadati trattati da provider e CDN. Per una versione orientata alla minimizzazione, considerare feed sincronizzati con servizio UE; anche questo richiede analisi dei ruoli, contratti e log.
3. Verificare ePrivacy/norme nazionali per memorizzazioni sul terminale e servizi terzi. L’assenza di analytics non equivale a conformità automatica. Non aggiungere banner cookie privi di necessità concreta.
4. Determinare l’applicabilità del Cyber Resilience Act in base a distribuzione e attività commerciale. La gratuità da sola non esclude gli obblighi. Valutare classificazione, documentazione tecnica, gestione vulnerabilità, supporto, SBOM, aggiornamenti e conformità ove richiesti. Le disposizioni principali si applicano dall’11 dicembre 2027; gli obblighi di reporting pertinenti dall’11 settembre 2026. Non attribuire automaticamente al nostro software gli incidenti rilevati su prodotti altrui.
5. Stabilire licenza del progetto, attribution e obblighi delle dipendenze, policy di disclosure, canale di segnalazione, firma e verifica degli aggiornamenti. Nessuna licenza open source è stata scelta per conto dell’autore.
6. Valutare accessibilità e obblighi consumer secondo servizio offerto e soggetto distributore. Verificare screen reader, contrasto, ingrandimento, navigazione tastiera e usabilità su hardware reale.
7. Verificare regole App Store/Play Store, privacy labels/data safety, dichiarazioni dei permessi e meccanismi di consenso. Niente richieste di privilegi non necessari.
8. Testare sicurezza del software e delle dipendenze e i percorsi permesso negato/concesso/revocato su Android e iOS reali. Testare Safari e Chrome reali: la compilazione web non prova i comportamenti di rete.

## Fonti ufficiali

- GDPR: https://eur-lex.europa.eu/eli/reg/2016/679/oj
- Commissione, principi GDPR: https://commission.europa.eu/law/law-topic/data-protection/information-business-and-organisations/principles-gdpr_en
- CRA e date: https://digital-strategy.ec.europa.eu/en/policies/cra-summary
- CRA e open source: https://digital-strategy.ec.europa.eu/en/policies/cra-open-source
- Apple, privacy rete locale: https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy
- Android, permesso locale: https://developer.android.com/privacy-and-security/local-network-permission
- Chrome, rete locale e CORS: https://developer.chrome.com/docs/modern-web-guidance/guides/security/local-network-access
