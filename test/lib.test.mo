import ChaChaRNG "../src";

let key : Blob = "\14\C9\72\09\03\D4\D5\72\82\95\E5\43\AF\FA\A9\44\49\2F\25\56\13\F3\6E\C7\B0\87\DC\76\08\69\14\CF";
let nonce : Blob = "\E5\43\AF\FA\A9\44\49\2F\25\56\13\F3";
let RNG = ChaChaRNG.RNG(key, nonce, 8);

let randomBytes = RNG.getRandomBytes(3);
assert randomBytes[0] == 96;
assert randomBytes[1] == 186;
assert randomBytes[2] == 111;

assert RNG.getRandomNumber(0, 100) == 42;

let randomNumbers = RNG.getRandomNumbers(0, 100, 3);
assert randomNumbers[0] == 97;
assert randomNumbers[1] == 38;
assert randomNumbers[2] == 42;