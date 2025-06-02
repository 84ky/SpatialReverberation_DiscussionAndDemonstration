import("stdfaust.lib");
process = no.pink_noise * (1 - a) : (+ : mem) ~ *(a);
a = 0.99;