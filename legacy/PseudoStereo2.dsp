import("stdfaust.lib");
process = no.pink_noise  <: _, (de.delay(ma.SR, del) <: _, _), ma.neg : +, +;
del = hslider("Delay", 0, 0, 0.150, 0.001) : ba.sec2samp;