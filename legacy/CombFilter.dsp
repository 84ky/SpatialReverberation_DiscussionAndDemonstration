import("stdfaust.lib");
combFIR = no.pink_noise  <:  de.delay(ma.SR, del) + _;
del = hslider("Delay", 0, 0, 0.15, 0.001) : ba.sec2samp;

//Sintassi per il feedback
combIIR = (- : de.delay(ma.SR, 20)) ~ *(0.85);
process = os.impulse : combIIR <: _, _;
gain = hslider("Feedback", 0, 0, 0.999, 0.001) : si.smoo;