declare vendor "bacons";
declare author "Michele";
declare name "Schroeder complementary comb filters";


import("stdfaust.lib");
process = _, !  <: _, (del1 <: del1, *(2)) : +, _ : sums;
del1 = de.delay(ma.SR, del);
del = hslider("Delay", 0, 0, 0.150, 0.001) : ba.sec2samp;
sums(a, b) = (a + b), (-a + b);