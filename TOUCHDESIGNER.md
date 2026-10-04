# TouchDesigner e OSC: stato del prototipo

`kendall_martens_decker.dsp` contiene ora il riverbero a parametri statici: le
liste dei ritardi e dei guadagni sono nel codice Faust, l'ingresso è mono e
l'uscita è mono. Il DSP non espone controlli OSC. Di conseguenza, inviare i
messaggi prodotti da `image18_control.py` non modifica il riverbero attuale.

## Stato dei valori numerici

La struttura generale del DSP riprende la rete descritta nel capitolo, ma i
valori numerici attualmente presenti sono provvisori e approssimativi. In
particolare, non devono essere considerati parametri recuperati dal software
originale:

- i ritardi del suono diretto e delle riflessioni;
- i coefficienti di attenuazione delle riflessioni e del ricircolo;
- i coefficienti e le frequenze dei filtri di assorbimento e dei filtri
  direzionali;
- `damping = 0.6` e `crossfeedGain = 0.2`.

Il capitolo descrive la presenza di filtri passa-basso nei percorsi di
feedback e il collegamento tramite crossfeed, ma non specifica un parametro
globale chiamato `damping` né fornisce un valore numerico per il guadagno del
crossfeed. I due valori nel DSP sono quindi regolazioni temporanee necessarie
per provare la rete, non dati storicamente documentati.

Ritardi, direzioni, attenuazioni delle riflessioni e filtri dovranno essere
ricalcolati e correlati tra loro durante la ricostruzione di `framer` e
`image18`. `framer` dovrà produrre i valori della configurazione spaziale nel
tempo; `image18` dovrà risolvere il modello delle sorgenti immagine e produrre
i parametri destinati al motore audio.

`space18` va mantenuto distinto sia dall'algoritmo generale descritto nel
capitolo sia dall'attuale riverbero Faust. Era un altro software storico: il
capitolo lo presenta come una particolare implementazione della rete di
riverberazione, non come il nome dell'algoritmo e neppure come il suo codice
sorgente completo. La sua architettura documentata può servire come riferimento
per confrontare la ricostruzione, ma non permette da sola di affermare che il
cablaggio Faust coincida con quello del programma. Fino alla ricostruzione dei
programmi e dei dati di controllo, i valori correnti servono soltanto a
verificare che la topologia Faust compili e funzioni.

`image18_control.py` rimane come prototipo separato per calcolare i parametri
geometrici di una stanza rettangolare. Produce 105 indirizzi OSC per un DSP che
esponga ritardi, guadagni e pan per il suono diretto, sei riflessioni di primo
ordine e dodici di secondo ordine. Le sue formule di guadagno e pan sono
approssimazioni aggiunte durante questa ricostruzione, non dati recuperati dai
programmi storici. Anche questo prototipo dovrà quindi essere verificato e
adattato alla ricostruzione di `framer` e `image18`, confrontandone poi
l'interfaccia con quanto documentato per `space18`.

Per collegare in futuro TouchDesigner al DSP corrente occorre prima esporre in
Faust i ritardi e i guadagni come controlli aggiornabili e stabilire il formato
dei messaggi. Un'architettura Faust con OSC può ricevere quei controlli;
TouchDesigner può generare i frame in un Execute DAT e trasmetterli tramite un
OSC Out DAT. L'uscita stereo e la direzionalizzazione binaurale richiedono una
scelta progettuale separata: il file Faust attuale conserva la somma mono del
codice originale.

Riferimenti: [Faust OSC](https://faustdoc.grame.fr/manual/osc/),
[OSC Out DAT](https://docs.derivative.ca/OSC_Out_DAT),
[Execute DAT](https://docs.derivative.ca/Execute_DAT).
