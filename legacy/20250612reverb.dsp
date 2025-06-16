import("stdfaust.lib");


//Segnale diretto dalla sorgente
distance = 10; //distanza della sorgente in metri
directDelay = distance/344;
sourceInlet = _ : fi.lowpass(2, 20000) : de.delay(ma.SR/10, ba.sec2samp(directDelay)) : fi.tf2s(0,0,1,sqrt(2),1,ma.PI*ma.SR/2);

//Primo filtro del riverberatore
firstFilter = _ : fi.lowpass(2, 18000) : _;

//Riflessioni di primo ordine
first_del_list = 0.05, 0.06, 0.055, 0.065, 0.075, 0.08; //tra i 50 e gli 80 ms
first_coef_list = 0.05, 0.05, 0.05, 0.05, 0.05, 0.05;
firstOrderDelays =  _ <: par(i, 6, de.delay(ma.SR/10, ba.sec2samp(ba.take(i+1,first_del_list))) *(ba.take(i+1,first_coef_list)));

r2Unit_del1_list = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;
r2Unit_del2_list = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;

//capisci come mettere i giusti valori di fi.iir
r2unit(t1,t2,g1,g2) = _<: (+ : de.delay(ma.SR/10,ba.sec2samp(t1)) : fi.iir(g1, (1-g1)) <: (de.delay(ma.SR/10,ba.sec2samp(t1)) : fi.iir(g1, (1-g1))),_)~_, _ :>_;

directionalizer = fi.tf2s(0,0,1,sqrt(2),1,ma.PI*ma.SR/2);

firstOrderReflections = _  : firstOrderDelays : par(i, 6, r2unit(ba.take(i+1, r2Unit_del1_list), ba.take(i+1, r2Unit_del2_list), 0.5, 0.5)) : par(i, 6, directionalizer) :> _;

//Riflessioni del secondo ordine
second_del_list = 0.05, 0.06, 0.055, 0.065, 0.075, 0.08, 0.25, 0.115, 0.2, 0.22, 0.13, 0.3; //tra i 50 e gli 300 ms in base alle dimensioni della stanza
second_coef_list = 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05, 0.05;
secondOrderDelays =  _ <: par(i, 12, de.delay(ma.SR/10, ba.sec2samp(ba.take(i+1,second_del_list))) *(ba.take(i+1,second_coef_list)));
r2Unit_del1_list2 = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2, 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;
r2Unit_del2_list2 = 0.1, 0.2, 0.5, 0.77, 0.3, 0.2, 0.1, 0.2, 0.5, 0.77, 0.3, 0.2;

secondOrderRefections = _ : fi.lowpass(2, 16000) : secondOrderDelays : par(i, 12, r2unit(ba.take(i+1, r2Unit_del1_list2), ba.take(i+1, r2Unit_del2_list2), 0.5, 0.5)) : par(i, 12, directionalizer) :> _;

process = ba.pulsen(1, 48000) <: sourceInlet, (firstFilter <: firstOrderReflections, secondOrderRefections) :> _;