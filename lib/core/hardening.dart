class HardeningStep {
  const HardeningStep(
    this.id,
    this.title,
    this.why,
    this.action,
    this.verify,
    this.source,
  );
  final String id, title, why, action, verify, source;
}

const hardeningSteps = [
  HardeningStep(
    'remote-admin',
    'Tieni il pannello del router nella rete fidata',
    'L’amministrazione da Internet aumenta la superficie di attacco.',
    'Nel router cerca “Amministrazione remota”, “Accesso da WAN” o “Web access from Internet” e disattivali se non servono. '
        'Consenti il pannello solo dai tuoi dispositivi fidati. Non disattivare alla cieca i servizi di gestione del tuo operatore.',
    'Controlla IPv4 e IPv6. Una verifica dalla LAN, anche verso l’IP pubblico, non dimostra il blocco da Internet. '
        'Serve una prova autorizzata da una rete esterna; il PoC non la esegue.',
    'https://csrc.nist.gov/pubs/ir/8425/a/final',
  ),
  HardeningStep(
    'camera-cloud',
    'Controlla chi può vedere le telecamere',
    'Cloud e P2P possono consentire accesso remoto anche senza port forwarding.',
    'Nell’app del produttore controlla “Accesso remoto”, “P2P”, “Cloud”, utenti condivisi e sessioni attive. '
        'Rimuovi gli accessi sconosciuti, attiva MFA se disponibile e disattiva l’accesso remoto che non usi. '
        'Se ti serve accesso da fuori, valuta una VPN mantenuta e accessi limitati invece di esporre direttamente la camera.',
    'Verifica separatamente camera, registratore NVR e account cloud. Il PoC non accede ai tuoi account e non prova la visione di immagini.',
    'https://www.onvif.org/profiles/whitepapers/onvif-recommendations-for-cybersecurity-best-practices-for-ip-based-physical-security-products/',
  ),
  HardeningStep(
    'forwarding',
    'Rivedi le porte aperte verso casa',
    'Un inoltro può rendere accessibile un dispositivo da Internet.',
    'Nel router cerca “Port forwarding”, “Virtual server”, “Port triggering” e “DMZ host”. '
        'Rimuovi solo le regole che riconosci come inutili. Evita una DMZ verso camera o NAS. '
        'Controlla anche UPnP, PCP/NAT-PMP e le regole in ingresso IPv6.',
    'L’elenco UPnP del PoC può essere parziale e non rappresenta tutte le regole. '
        'Non cambiare le porte per nascondere un servizio: limita davvero gli accessi.',
    'https://csrc.nist.gov/pubs/ir/8425/a/final',
  ),
  HardeningStep(
    'upnp',
    'Scegli se ti serve UPnP',
    'Può permettere ai dispositivi locali di chiedere aperture sul router.',
    'Se non ti serve, disattivalo nel router. Se lo usi per giochi o altri servizi, '
        'controlla regolarmente quali dispositivi creano le regole e limita UPnP alle reti necessarie, se il router lo permette.',
    'Ripeti il controllo dopo la modifica. Una mancata risposta SSDP non dimostra che UPnP sia spento.',
    'https://www.cyber.gc.ca/en/guidance/universal-plug-play-itsap00008',
  ),
  HardeningStep(
    'segments',
    'Separa fidati, IoT e ospiti',
    'Un dispositivo compromesso deve poter raggiungere il minor numero possibile di altri dispositivi.',
    'Fidati: PC e telefoni personali. IoT: telecamere, TV, prese, elettrodomestici. Ospiti: visitatori. '
        'Usa reti separate con regole firewall: IoT e ospiti non devono accedere alla rete fidata o al pannello del router. '
        'Consenti solo le comunicazioni necessarie, per esempio dal tuo telefono al registratore. '
        'Una rete con un nome Wi-Fi diverso, senza isolamento, non basta.',
    'Verifica l’isolamento da ciascuna rete, anche in IPv6. Casting, stampanti e hub possono richiedere eccezioni mirate. '
        'Il PoC non certifica la segmentazione da un solo punto della rete.',
    'https://www.nsa.gov/Press-Room/News-Highlights/Article/Article/3304674/nsa-releases-best-practices-for-securing-your-home-network/',
  ),
  HardeningStep(
    'legacy',
    'Spegni i servizi che non usi',
    'Telnet e FTP tradizionali possono trasmettere credenziali senza cifratura.',
    'Nelle impostazioni cerca Telnet, FTP, SSH, condivisioni file e desktop remoto. '
        'Disattiva quelli inutilizzati; per l’amministrazione preferisci protocolli cifrati e accessi dalla sola rete fidata. '
        'Una porta aperta è un indizio: conferma il servizio prima di cambiarlo.',
    'Ripeti il controllo dopo il cambiamento. Le porte non standard e i servizi non coperti possono sfuggire.',
    'https://www.onvif.org/profiles/whitepapers/onvif-recommendations-for-cybersecurity-best-practices-for-ip-based-physical-security-products/',
  ),
  HardeningStep(
    'updates',
    'Aggiorna e controlla la fine del supporto',
    'Le correzioni dipendono da modello, revisione hardware e firmware esatti.',
    'Usa l’app o il sito ufficiale del produttore, abilita gli aggiornamenti automatici se disponibili '
        'e verifica fino a quando il prodotto è supportato. Prima di un aggiornamento segui la procedura di backup del produttore.',
    'Confronta la versione dopo l’aggiornamento. Se il supporto è terminato, pianifica la sostituzione e limita nel frattempo la connettività.',
    'https://www.nsa.gov/Press-Room/News-Highlights/Article/Article/3304674/nsa-releases-best-practices-for-securing-your-home-network/',
  ),
  HardeningStep(
    'accounts',
    'Proteggi account e condivisioni',
    'Un account cloud compromesso può aggirare le difese della rete domestica.',
    'Scegli password uniche per router, dispositivi e cloud; usa un password manager, '
        'attiva MFA e togli gli account inutili. Non inserire password dentro Netscan.',
    'Controlla utenti condivisi, sessioni attive, notifiche di accesso e metodi di recupero.',
    'https://consumer.ftc.gov/articles/securing-your-internet-connected-devices-home',
  ),
  HardeningStep(
    'wifi',
    'Controlla Wi-Fi e firewall',
    'Cifratura e regole in ingresso proteggono l’accesso alla rete.',
    'Usa WPA3 quando compatibile o almeno WPA2 con AES; evita WEP e TKIP. '
        'Disattiva WPS se non ti serve e mantieni attivi i firewall IPv4 e IPv6.',
    'Queste impostazioni vanno controllate nel router: non sono misurate dalla scansione TCP.',
    'https://consumer.ftc.gov/articles/how-secure-your-home-wi-fi-network',
  ),
  HardeningStep(
    'recovery',
    'Prepara recupero e controllo periodico',
    'Sicurezza significa anche accorgersi dei cambiamenti e poter ripristinare.',
    'Conserva un backup protetto delle configurazioni, controlla dispositivi sconosciuti e avvisi del produttore. '
        'Quando cedi una camera, rimuovi le condivisioni cloud, scollega l’account ed esegui il reset previsto dal produttore.',
    'Rivedi la configurazione dopo nuovi dispositivi, aggiornamenti importanti e cambi di router.',
    'https://www.etsi.org/deliver/etsi_en/303600_303699/303645/03.01.03_60/en_303645v030103p.pdf',
  ),
];
