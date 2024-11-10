import ChaChaRNG "../src";

// This ChaCha20 implementation uses the test vectors from Section 2.3.2 of RFC 8439:
// "ChaCha20 and Poly1305 for IETF Protocols" (https://datatracker.ietf.org/doc/html/rfc8439#section-2.3.2).

// As described in that section, after setting up the ChaCha state, the state should look like this:

//      61707865  3320646e  79622d32  6b206574
//      03020100  07060504  0b0a0908  0f0e0d0c
//      13121110  17161514  1b1a1918  1f1e1d1c
//      00000001  09000000  4a000000  00000000

// Where:
// - The first four words (0-3) are constants
// - The next eight words (4-11) are taken from the 256-bit key in 4-byte chunks.
// - Word 12 is a block counter
// - Words 13-15 are a nonce

// Therefore, the ChaCha block structure looks like this:

//      cccccccc  cccccccc  cccccccc  cccccccc
//      kkkkkkkk  kkkkkkkk  kkkkkkkk  kkkkkkkk
//      kkkkkkkk  kkkkkkkk  kkkkkkkk  kkkkkkkk
//      bbbbbbbb  nnnnnnnn  nnnnnnnn  nnnnnnnn

// Where:
// - c = constant
// - k = key
// - b = block counter
// - n = nonce

// According to the test vector, we should set up the key and nonce as follows:
// key:      03020100  07060504  0b0a0908  0f0e0d0c 13121110  17161514  1b1a1918  1f1e1d1c
// nonce:    09000000  4a000000  00000000

// We set up the key and nonce in Blob format
let key : Blob = "\03\02\01\00\07\06\05\04\0b\0a\09\08\0f\0e\0d\0c\13\12\11\10\17\16\15\14\1b\1a\19\18\1f\1e\1d\1c";
let nonce : Blob = "\09\00\00\00\4a\00\00\00\00\00\00\00";

// We run 20 rounds (10 column rounds interleaved with 10 "diagonal rounds")
let RNG = ChaChaRNG.RNG(key, nonce, 20);
let randomNumbers = RNG.getRandomNumbers(0, 0xFFFFFFFF, 16);

// The ChaCha state at the end of the ChaCha20 operation should be:

//      e4e7f110  15593bd1  1fdd0f50  c47120a3
//      c7f4d1c7  0368c033  9aaa2204  4e6cd4c3
//      466482d2  09aa9f07  05d7c214  a2028bd9
//      d19c12b5  b94e16de  e883d0cb  4e3c50a2

assert randomNumbers[0] == 0xe4e7f110;
assert randomNumbers[1] == 0x15593bd1;
assert randomNumbers[2] == 0x1fdd0f50;
assert randomNumbers[3] == 0xc47120a3;
assert randomNumbers[4] == 0xc7f4d1c7;
assert randomNumbers[5] == 0x0368c033;
assert randomNumbers[6] == 0x9aaa2204;
assert randomNumbers[7] == 0x4e6cd4c3;
assert randomNumbers[8] == 0x466482d2;
assert randomNumbers[9] == 0x09aa9f07;
assert randomNumbers[10] == 0x05d7c214;
assert randomNumbers[11] == 0xa2028bd9;
assert randomNumbers[12] == 0xd19c12b5;
assert randomNumbers[13] == 0xb94e16de;
assert randomNumbers[14] == 0xe883d0cb;
assert randomNumbers[15] == 0x4e3c50a2;
