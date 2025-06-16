import("stdfaust.lib");

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



lowPassCoeffs(cutFreq, qFactor, sampleRate) = (b2, b1, b0, a2, a1)
  with {
    w0 = 2 * ma.PI * (cutFreq / sampleRate);
    alpha = sin(w0) / (2 * qFactor);
    b0 = (1 - cos(w0)) / 2;
    b1 = 1 - cos(w0);
    b2 = (1 - cos(w0)) / 2;
    //a0 = 1 + alpha;
    a1 = -2 * cos(w0);
    a2 = 1 - alpha;
  };



highPassCoeffs(cutFreq, qFactor, sampleRate) = (b2, b1, b0, a2, a1)
  with {
    w0 = 2 * ma.PI * (cutFreq / sampleRate);
    alpha = sin(w0) / (2 * qFactor);
    b0 = (1 + cos(w0)) / 2;
    b1 = -(1 + cos(w0));
    b2 = (1 + cos(w0)) / 2;
    //a0 = 1 + alpha;
    a1 = -2 * cos(w0);
    a2 = 1 - alpha;
  };


bandPassCoeffsConstSkirtGain(cutFreq, qFactor, sampleRate) = (b2, b1, b0, a2, a1)
  with {
    w0 = 2 * ma.PI * (cutFreq / sampleRate);
    alpha = sin(w0) / (2 * qFactor);
    b0 = sin(w0) / 2;
    b1 = 0;
    b2 = -(sin(w0)/2);
    //a0 = 1 + alpha;
    a1 = -2 * cos(w0);
    a2 = 1 - alpha;
  };


bandPassCoeffsConst0db(cutFreq, qFactor, sampleRate) = (b2, b1, b0, a2, a1)
  with {
    w0 = 2 * ma.PI * (cutFreq / sampleRate);
    alpha = sin(w0) / (2 * qFactor);
    b0 = alpha;
    b1 = 0;
    b2 = -alpha;
    //a0 = 1 + alpha;
    a1 = -2 * cos(w0);
    a2 = 1 - alpha;
  };



notchCoeffs(cutFreq, qFactor, sampleRate) = (b2, b1, b0, a2, a1)
  with {
    w0 = 2 * ma.PI * (cutFreq / sampleRate);
    alpha = sin(w0) / (2 * qFactor);
    b0 = 1;
    b1 = -2*cos(w0);
    b2 = 1;
    //a0 = 1 + alpha;
    a1 = -2 * cos(w0);
    a2 = 1 - alpha;
  };



allPassCoeffs(cutFreq, qFactor, sampleRate) = (b2, b1, b0, a2, a1)
  with {
    w0 = 2 * ma.PI * (cutFreq / sampleRate);
    alpha = sin(w0) / (2 * qFactor);
    b0 = 1 - alpha;
    b1 = -2*cos(w0);
    b2 = 1 + alpha;
    //a0 = 1 + alpha;
    a1 = -2 * cos(w0);
    a2 = 1 - alpha;
  };



peakingEQCoeffs(cutFreq, dbGain, qFactor, sampleRate) = (b2, b1, b0, a2, a1)
  with {
    amp = 10^(dbGain/40);
    w0 = 2 * ma.PI * (cutFreq / sampleRate);
    alpha = sin(w0) / (2 * qFactor);
    b0 = 1 + (alpha * amp);
    b1 = -2*cos(w0);
    b2 = 1 - (alpha * amp);
    //a0 = 1 + (alpha/amp);
    a1 = -2 * cos(w0);
    a2 = 1 - (alpha / amp);
  };



lowShelfCoeffs(cutFreq, dbGain, qFactor, sampleRate) = (b2, b1, b0, a2, a1)
  with {
    amp = 10^(dbGain/40);
    w0 = 2 * ma.PI * (cutFreq / sampleRate);
    alpha = sin(w0) / (2 * qFactor);
    b0 = amp*((amp + 1) - (amp - 1)*cos(w0) + 2*sqrt(amp)*alpha);
    b1 = 2*amp*((amp - 1) - (amp + 1)*cos(w0));
    b2 = amp*((amp + 1) - (amp - 1)*cos(w0) - 2*sqrt(amp)*alpha);
    //a0 = (amp + 1) + (amp - 1)*Cos(w0) + 2*Sqrt(amp)*alpha;
    a1 = -2*((amp - 1) + (amp + 1)*cos(w0));
    a2 = (amp + 1) + (amp - 1)*cos(w0) - 2*sqrt(amp)*alpha;
  };



highShelfCoeffs(cutFreq, dbGain, qFactor, sampleRate) = (b2, b1, b0, a2, a1)
  with {
    amp = 10^(dbGain/40);
    w0 = 2 * ma.PI * (cutFreq / sampleRate);
    alpha = sin(w0) / (2 * qFactor);
    b0 = amp*((amp + 1) + (amp - 1)*cos(w0) + 2*sqrt(amp)*alpha);
    b1 = -2*amp*((amp - 1) + (amp + 1)*cos(w0));
    b2 = amp*((amp + 1) + (amp - 1)*cos(w0) - 2*sqrt(amp)*alpha);
    //a0 = (amp + 1) - (amp - 1)*cos(w0) + 2*sqrt(amp)*alpha;
    a1 = 2*((amp - 1) - (amp + 1)*cos(w0));
    a2 = (amp + 1) - (amp - 1)*cos(w0) - 2*sqrt(amp)*alpha;
  };



//coeffs = lowPassCoeffs(cutFreq, qFactor, sampleRate);
//coeffs = highPassCoeffs(cutFreq, qFactor, sampleRate);
//coeffs = bandPassCoeffsConstSkirtGain(cutFreq, qFactor, sampleRate);
//coeffs = bandPassCoeffsConst0db(cutFreq, qFactor, sampleRate);
//coeffs = notchCoeffs(cutFreq, qFactor, sampleRate);
//coeffs = allPassCoeffs(cutFreq, qFactor, sampleRate);
//coeffs = peakingEQCoeffs(14000, -12, 2.5, 48000);
//coeffs = lowShelfCoeffs(9000, -3, 0.81, 48000);
coeffs = highShelfCoeffs(14000, 2, 0.8, 48000);

b2 = ba.take(1, coeffs);
b1 = ba.take(2, coeffs);
b0 = ba.take(3, coeffs);
a2 = ba.take(4, coeffs);
a1 = ba.take(5, coeffs);

//process = no.pink_noise : biQuad(b2, b1, b0, a2, a1);
process = no.pink_noise <: _, biQuad(b2, b1, b0, a2, a1);