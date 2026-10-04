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
firstOrderDelays =  _ <: par(i, 6, de.delay(ma.SR*4, ba.sec2samp(ba.take(i+1,first_del_list))) *(ba.take(i+1,first_coef_list)));

r2Unit_del1_list = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;
r2Unit_del2_list = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;

//capisci come mettere i giusti valori di fi.iir
r2unit(t1,t2,g1) = _<: (+ : de.delay(ma.SR*4,ba.sec2samp(t1)) : fi.iir(g1, (1-g1)) <: (de.delay(ma.SR*4,ba.sec2samp(t1)) : fi.iir(g1, (1-g1))),_)~_, _ :>_;



biQuad(b2, b1, b0, a2, a1) = fir(b2, b1, b0) : ma.sub ~ iir(a2, a1) //il feedback introduce sempre già un campione di ritardo
    with{
        b2c(b2) = @(2) * (b2); // segnale in ingresso, ritardato di due campioni
        b1c(b1) = @(1) * (b1);
        b0c(b0) =  * (b0);
        a2c(a2) = @(1) : * (a2);
        a1c(a1) = * (a1);
        fir(b2, b1, b0) = _ <: b2c(b2), b1c(b1), b0c(b0) :> _;
        iir(a2, a1) = _ <: a2c(a2), a1c(a1) :> _;
    };




directionalizer = _ : biQuad(0.720111, -1.45271, 2.48071, 0.734462, -1.09213) : biQuad(0.871035, -1, 1.12896, 0.636528, -1) : biQuad(0.58389, -0.261052, 1.41611, 0.852358, -0.261052) : biQuad(0.903178, 0.517638, 1.09682, 0.614545, 0.517638) : biQuad(0.910503, 0.958653, 3.78052, 0.874648, 1.34247);    
firstOrderReflections = _  : firstOrderDelays : par(i, 6, r2unit(ba.take(i+1, r2Unit_del1_list), ba.take(i+1, r2Unit_del2_list), 0.5)) : par(i, 6, directionalizer) :> _;

//Riflessioni del secondo ordine

r1unit(t1, g1) = _ <: (
    (((+ : de.delay(ma.SR*4,ba.sec2samp(t1))) : fi.iir(g1, (1-g1))) ~ *(1)),
    _) :> +;

second_del_list = 0.05, 0.06, 0.055, 0.065, 0.075, 0.08, 0.25, 0.115, 0.2, 0.22, 0.13, 0.3; //tra i 50 e gli 300 ms in base alle dimensioni della stanza
second_coef_list = 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05;
secondOrderDelays =  _ <: par(i, 12, de.delay(ma.SR*4, ba.sec2samp(ba.take(i+1,second_del_list))) *(ba.take(i+1,second_coef_list)));

r1Unit_del_list = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2, 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;
r1Unit_gain_list = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2, 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;

r2Unit_del1_list2 = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2, 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;
r2Unit_del2_list2 = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2, 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;

secondOrderRefections = _ : fi.lowpass(2, 16000) : secondOrderDelays : par(i, 12, r1unit(ba.take(i+1, r1Unit_del_list), ba.take(i+1, r1Unit_gain_list))) : par(i, 12, r2unit(ba.take(i+1, r2Unit_del1_list2), ba.take(i+1, r2Unit_del2_list2), 0.5)) : par(i, 12, directionalizer) :> _;

process = _ <: sourceInlet, (firstFilter <: firstOrderReflections, secondOrderRefections) :> _;
