import("stdfaust.lib");
//l'ordine del filtro é in base alla quantità dei campioni di ritardo.
process = no.pink_noise : biQuad(0, 0.5, 0.5, 0, 0);
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