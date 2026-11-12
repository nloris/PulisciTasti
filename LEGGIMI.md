# PulisciTasti

Una piccola app nativa per pulire la tastiera del Mac: apri, pulisci i tasti, clicca la **X** per sbloccare e uscire. Il trackpad resta attivo.

## Novità della versione 1.1

- Grafica minimale che segue l’aspetto chiaro/scuro di macOS.
- Tastiera illustrata che reagisce alle pressioni bloccate.
- Contatore delle pressioni della sessione.
- Timer opzionale da 2, 5 o 10 minuti, con sblocco automatico alla scadenza. Di default non c’è un limite; cambiare durata fa ripartire il conto alla rovescia.
- Interfaccia in italiano e inglese.
- Icona dedicata e build universale per Apple Silicon e Intel.

## Primo avvio

1. Apri **PulisciTasti.app**. Se vuoi spostarla in Applicazioni, fallo prima di concedere il permesso.
2. Clicca **Apri Accessibilità** e abilita **PulisciTasti** in Impostazioni di Sistema → Privacy e sicurezza → Accessibilità. Se non compare, aggiungila con **+**.
3. Torna all’app. Inizia la pulizia solo quando compare **TASTIERA PROTETTA**. Se necessario, chiudi e riapri dopo avere concesso il permesso.
4. Clicca la **X in alto a destra** per sbloccare e chiudere. Anche l’icona nella barra dei menu sblocca e chiude.

La nuova build potrebbe richiedere di concedere nuovamente il permesso. Quando un timer finisce, il blocco non riparte da solo.

## Compatibilità e limiti

macOS 13 o successivo. La build contiene Apple Silicon e Intel; la verifica diretta su hardware è stata effettuata su Apple Silicon.

**Accensione e Touch ID restano attivi.** Non è una schermata di sicurezza né un pulitore di file. Il filtro intercetta gli eventi di tastiera consegnati da macOS, compresi i multimediali quando passano da questo flusso. I comportamenti gestiti direttamente dall’hardware possono differire. Se macOS attiva l’inserimento protetto, per esempio in un campo password, l’app rimuove il blocco e mostra lo stato libero; il controllo è periodico. Chiudere o terminare il processo rimuove il filtro.

Questa prima release è firmata ad hoc, **non notarizzata da Apple**: macOS potrebbe bloccare la copia scaricata. Per ora la compilazione locale è il metodo consigliato per gli altri utenti.

## Privacy e sorgenti

Nessuna rete, account o telemetria. Per l’animazione viene mantenuta brevemente in memoria la posizione numerica dell’ultimo tasto; il contatore vale solo per la sessione. Non vengono conservati testi digitati o registri di tasti.

Per compilare con gli strumenti da riga di comando di Xcode: `zsh build.sh`. `--self-test` verifica filtro e timer; `--preview` mostra una demo senza bloccare la tastiera. I test automatici non sostituiscono la verifica su hardware con Accessibilità autorizzata.

Licenza [MIT](LICENSE). Documentazione completa in [inglese](README.md).
