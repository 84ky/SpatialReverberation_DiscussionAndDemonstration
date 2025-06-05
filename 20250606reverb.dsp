import("stdfaust.lib");

notchFilter = _ :@(2) : _; //devono variare dinamicamente per simulare lo spostamento della sorgente

notchAmbientAbsorption =  _ : @(2) : @(2) : _;



//distance = 10; //in  metri
//initialDelaySamps(distance) = int((distance* ma.SR)/343);

//fi.lowpass va sostituito con un filtro feedback
R1unit = _ <: (
    (((+ : mem) : fi.fb_comb(32, 4, 0, 0)) ~ *(1)),
    _) :> +;

r2_first_del1_list = 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2;
r2_first_del2_list = 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2;

r2_second_del1_list = 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2;
r2_second_del2_list = 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2;

r2unit(t1,t2,g1,g2) = _<: (+ : de.delay(ma.SR/10,ba.sec2samp(t1)) : fi.iir(g1, (1-g1)) <: (de.delay(ma.SR/10,ba.sec2samp(t1)) : fi.iir(g1, (1-g1))),_)~_, _ :>_;

//process = r2unit(0.1,0.2,0.75,0.5);


sourceInlet = _ : notchAmbientAbsorption : @(1) : notchFilter;



a1= 0.75;
a2= 0.75;
a3= 0.75;
a4= 0.75;
a5= 0.75;
a6= 0.75;
//firstOrderDelays = _ <: @(100), @(200), @(120), @(150), @(180), @(187) : _, _, _, _, _, _;
first_del_list = 0.1, 0.2, 0.3, 0.4, 0.5, 0.6;
first_del_coef = 0.75, 0.75, 0.75, 0.75, 0.75, 0.75;
firstOrderDelays = _ <: par(i, 6, de.delay(ma.SR/10, ba.sec2samp(ba.take(i+1,first_del_list))) *(ba.take(i+1,first_del_coef)));


filterFirstOrder = _ : notchAmbientAbsorption : @(1) : _;
firstOrderCoeffs = _*(a1), _*(a2), _*(a3), _*(a4), _*(a5), _*(a6);
directionalizer = fi.tf2s(0,0,1,sqrt(2),1,ma.PI*ma.SR/2);
//process = directionalizer;

firstOrderDirectionalizer = notchFilter, notchFilter, notchFilter, notchFilter, notchFilter, notchFilter;
firstOrderReflections = _ : filterFirstOrder <: firstOrderDelays : par(i,6,r2unit(ba.take(i+1,r2_first_del1_list),ba.take(i+1,r2_first_del1_list),0.5,0.5)) : par(i,6,directionalizer) :> +;




b1 = 0.65;
b2 = 0.65;
b3 = 0.65;
b4 = 0.65;
b5 = 0.65;
b6 = 0.65;
b7 = 0.65;
b8 = 0.65;
b9 = 0.65;
b10 = 0.65;
b11 = 0.65;
b12 = 0.65;
secondOrderCoeffs = _*(b1), _*(b2), _*(b3), _*(b4), _*(b5), _*(b6), _*(b7), _*(b8), _*(b9), _*(b10), _*(b11), _*(b12);
secondOrderDelays = _ <: @(4800), @(3000), @(2000), @(1000), @(800), @(1500), @(1700), @(2300), @(2700), @(3300), @(3800), @(900) : _, _, _, _, _, _, _, _, _, _, _, _;
filterSecondOrder = _ : filterFirstOrder : notchAmbientAbsorption : _;
secondOrderDirectionalizer = notchFilter, notchFilter, notchFilter, notchFilter, notchFilter, notchFilter, notchFilter, notchFilter, notchFilter, notchFilter, notchFilter, notchFilter;
secondOrderReflections = _ : filterSecondOrder : secondOrderDelays : secondOrderCoeffs : R1unit, R1unit, R1unit, R1unit, R1unit, R1unit, R1unit, R1unit, R1unit, R1unit, R1unit, R1unit : par(i,12,r2unit(0.1,0.1,0.5,0.5)) : secondOrderDirectionalizer :> +;






//process = ba.pulsen(1, 48000) <: sourceInlet, firstOrderReflections, secondOrderReflections :> +, _ : + <: _, _;
process = os.impulse <: sourceInlet, firstOrderReflections, secondOrderReflections :> +, _ :> + <: _, _;
//process = ba.pulsen(1, 96000) <: firstOrderReflections;