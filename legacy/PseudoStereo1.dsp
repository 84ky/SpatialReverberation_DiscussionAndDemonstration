import("stdfaust.lib");
process = os.osc(400)  <:  de.delay(ma.SR, del), _;
del = hslider("Delay", 0, 0, 1, 0.001) : ba.sec2samp;