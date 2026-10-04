import("stdfaust.lib");


//Segnale diretto dalla sorgente
distance = 10; //distanza della sorgente in metri
directDelay = distance/344;
sourceInlet = _ : fi.lowpass(2, 20000) : de.delay(ma.SR*4, ba.sec2samp(directDelay)) : directionalizer;

//Primo filtro del riverberatore
firstFilter = _ : fi.lowpass(2, 18000) : _;

//Riflessioni di primo ordine
first_del_list = 0.05, 0.06, 0.055, 0.065, 0.075, 0.08; //tra i 50 e gli 80 ms
first_coef_list = 0.05, 0.05, 0.05, 0.05, 0.05, 0.05;
firstOrderDelays(i,x) = x : de.delay(ma.SR*4, ba.sec2samp(ba.take(i+1,first_del_list)))
                           : *(ba.take(i+1,first_coef_list));

r2Unit_del1_list = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;
r2Unit_del2_list = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;
// Le due liste originali coincidono: t2 ora e' usato, ma i tempi non alternano.

// Filtro passa-basso nel ricircolo; g regola l'attenuazione a bassa frequenza.
// Il paper non fornisce il valore di damping o quello del crossfeed.
damping = 0.6;
crossfeedGain = 0.2;
feedbackFilter(g) = fi.iir(g*(1-damping), -damping);

// L'ingresso crossfeed entra nella ricircolazione, non nella riflessione iniziale.
// La seconda linea di ritardo usa t2, distinto da t1.
r2tail(t1,t2,g) = ((+ : de.delay(ma.SR*4,ba.sec2samp(t1)) : feedbackFilter(g)
                      <: ((de.delay(ma.SR*4,ba.sec2samp(t2)) : feedbackFilter(g)), _)) ~ _);
r2unit(t1,t2,g,early,cross) = early + (((early+cross) : r2tail(t1,t2,g)) :> _);



// I coefficienti riportati sotto sono quelli non normalizzati: a0 diventa 1
// dividendo sia il numeratore sia gli altri coefficienti del denominatore.
biQuad(b2, b1, b0, a2, a1, a0) = fir(b2/a0, b1/a0, b0/a0) : ma.sub ~ iir(a2/a0, a1/a0) //il feedback introduce sempre già un campione di ritardo
    with{
        b2c(b2) = @(2) * (b2); // segnale in ingresso, ritardato di due campioni
        b1c(b1) = @(1) * (b1);
        b0c(b0) =  * (b0);
        a2c(a2) = @(1) : * (a2);
        a1c(a1) = * (a1);
        fir(b2, b1, b0) = _ <: b2c(b2), b1c(b1), b0c(b0) :> _;
        iir(a2, a1) = _ <: a2c(a2), a1c(a1) :> _;
    };




// a0 ricavati dalle stesse cinque formule usate per i coefficienti originali (48 kHz).
directionalizer = _ : biQuad(0.720111, -1.45271, 2.48071, 0.734462, -1.09213, 2.826937297927)
                    : biQuad(0.871035, -1, 1.12896, 0.636528, -1, 1.363471731917)
                    : biQuad(0.58389, -0.261052, 1.41611, 0.852358, -0.261052, 1.147641542829)
                    : biQuad(0.903178, 0.517638, 1.09682, 0.614545, 0.517638, 1.385455080050)
                    : biQuad(0.910503, 0.958653, 3.78052, 0.874648, 1.34247, 3.432549816306);
//Riflessioni del secondo ordine

r1unit(t1,g,early,cross) = early + ((early+cross) : ((+ : de.delay(ma.SR*4,ba.sec2samp(t1)) : feedbackFilter(g)) ~ _));

second_del_list = 0.05, 0.06, 0.055, 0.065, 0.075, 0.08, 0.25, 0.115, 0.2, 0.22, 0.13, 0.3; //tra i 50 e gli 300 ms in base alle dimensioni della stanza
second_coef_list = 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05;
secondOrderDelays(i,x) = x : de.delay(ma.SR*4, ba.sec2samp(ba.take(i+1,second_del_list)))
                            : *(ba.take(i+1,second_coef_list));

r1Unit_del_list = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2, 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;
r1Unit_gain_list = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2, 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;

// Le liste contengono 6 tap di primo ordine per le pareti e 12 tap di secondo
// ordine per le giunzioni. I valori attuali sono provvisori e saranno sostituiti
// da quelli calcolati esternamente. Qui gli indici cablano soltanto il crossfeed.
firstTap(i,x) = firstOrderDelays(i,x);
secondTap(i,x) = secondOrderDelays(i,(x : fi.lowpass(2,16000)));

// Quattro R1 rappresentano le giunzioni del piano orizzontale.
horizontalJunctionIndex = 4,5,6,7;
horizontalJunction(i,x) = r1unit(
    ba.take(ba.take(i+1,horizontalJunctionIndex)+1,r1Unit_del_list),
    ba.take(ba.take(i+1,horizontalJunctionIndex)+1,r1Unit_gain_list),
    secondTap(ba.take(i+1,horizontalJunctionIndex),x),0);

// Ogni R2 laterale rappresenta una parete e riceve le due R1 adiacenti.
firstHorizontalJunction = 0,0,1,2;
secondHorizontalJunction = 3,1,2,3;
horizontalWall(i,x) = r2unit(
    ba.take(i+1,r2Unit_del1_list),ba.take(i+1,r2Unit_del2_list),0.5,
    firstTap(i,x),crossfeedGain*(
        horizontalJunction(ba.take(i+1,firstHorizontalJunction),x)+
        horizontalJunction(ba.take(i+1,secondHorizontalJunction),x)));

// Le altre otto R1 rappresentano le giunzioni dei piani verticali e
// ricevono il crossfeed dalla R2 laterale adiacente.
verticalJunctionIndex = 0,1,2,3,8,9,10,11;
adjacentHorizontalWall = 0,1,2,3,0,1,2,3;
verticalJunction(i,x) = r1unit(
    ba.take(ba.take(i+1,verticalJunctionIndex)+1,r1Unit_del_list),
    ba.take(ba.take(i+1,verticalJunctionIndex)+1,r1Unit_gain_list),
    secondTap(ba.take(i+1,verticalJunctionIndex),x),
    crossfeedGain*horizontalWall(ba.take(i+1,adjacentHorizontalWall),x));

// Le R2 di soffitto e pavimento ricevono le quattro giunzioni adiacenti.
ceilingWall(x) = r2unit(ba.take(5,r2Unit_del1_list),ba.take(5,r2Unit_del2_list),0.5,
    firstTap(4,x),crossfeedGain*(verticalJunction(0,x)+verticalJunction(1,x)+
                                verticalJunction(2,x)+verticalJunction(3,x)));
floorWall(x) = r2unit(ba.take(6,r2Unit_del1_list),ba.take(6,r2Unit_del2_list),0.5,
    firstTap(5,x),crossfeedGain*(verticalJunction(4,x)+verticalJunction(5,x)+
                                verticalJunction(6,x)+verticalJunction(7,x)));

r2Stream(i,x) = ba.take(i+1,(
    horizontalWall(0,x),horizontalWall(1,x),horizontalWall(2,x),horizontalWall(3,x),
    ceilingWall(x),floorWall(x)
));
r1Stream(i,x) = ba.take(i+1,(
    verticalJunction(0,x),verticalJunction(1,x),verticalJunction(2,x),verticalJunction(3,x),
    horizontalJunction(0,x),horizontalJunction(1,x),horizontalJunction(2,x),horizontalJunction(3,x),
    verticalJunction(4,x),verticalJunction(5,x),verticalJunction(6,x),verticalJunction(7,x)
));

firstOrderReflections(x) = par(i,6,directionalizer(r2Stream(i,x))) :> _;
secondOrderRefections(x) = par(i,12,directionalizer(r1Stream(i,x))) :> _;
innerReverb(x) = firstOrderReflections(x)+secondOrderRefections(x);
process = _ <: sourceInlet, (firstFilter : innerReverb) :> _;
