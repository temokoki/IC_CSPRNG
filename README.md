# Cryptographically secure pseudo-random number generator using the ChaCha algorithm for Motoko

## Overview

This CSPRNG, built with the ChaCha algorithm, generates secure random numbers ideal for cryptographic applications in Motoko.  
Unlike typical pseudo-random number generators (PRNGs), which are often predictable and lack robustness, this generator ensures high entropy, unpredictability, and resilience against cryptographic attacks.

### Key Features

* **High-Quality Randomness:** Produces uniformly distributed, high-entropy random values.
* **Non-Deterministic Initialization:** Relies on high-entropy seeds to ensure unpredictability and security.
* **Resilient to State Compromise:** Safeguards past and future outputs, even if part of the internal state is exposed.
* **Strong Security:** Uses ChaCha algorithm, a secure, high-performance stream cipher widely trusted in cryptographic protocols.

## Links

The package is published on [Mops](https://mops.one/csprng) and [GitHub](https://github.com/temokoki/IC_CSPRNG).  
See usage example on [Motoko Playground](https://m7sm4-2iaaa-aaaab-qabra-cai.raw.ic0.app/?tag=371826834)

## Usage

### Install with mops

You need [Mops](https://docs.mops.one/quick-start) installed.  
In your project directory run:

```
mops add csprng
```

In the Motoko source file import the package as:

```javascript
import ChaChaRNG "mo:csprng";
```

### Example

```javascript
import ChaChaRNG "mo:csprng";

// Note: Use unique key and nonce blobs for your dapp. See example with random key and nonce generation on Motoko Playground:
// https://m7sm4-2iaaa-aaaab-qabra-cai.raw.ic0.app/?tag=371826834

let key : Blob = "\14\C9\72\09\03\D4\D5\72\82\95\E5\43\AF\FA\A9\44\49\2F\25\56\13\F3\6E\C7\B0\87\DC\76\08\69\14\CF";
let nonce : Blob = "\E5\43\AF\FA\A9\44\49\2F\25\56\13\F3";

let cipherRounds = 8; //8, 12, and 20 are most common for ChaCha; More rounds increase security but consume more computation/cycles
    
let RNG = ChaChaRNG.RNG(key, nonce, cipherRounds); 

RNG.getRandomBytes(10)              //Generates 10 random bytes
RNG.getRandomNumber(0, 100);        //Generates single random number between 0 and 100
RNG.getRandomNumbers(0, 100, 10);   //Generates 10 random numbers between 0 and 100
```
