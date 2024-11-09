import Bench "mo:bench";
import Nat "mo:base/Nat";
import ChaChaRNG "../src";

module {
  public func init() : Bench.Bench {
    let bench = Bench.Bench();

    bench.name("RNG Efficiency with 12 Cipher Rounds");
    bench.description("Benchmarking across various ranges, with the module optimized to use minimal bytes per range, reducing computation by limiting new 64-byte encrypted block generation.");

    bench.rows(["0-255", "0–65.5K", "0–16.7M", "0–4.2B", "0-1.09T", "0-281T", "0–72Qa", "0–18.4Qi"]);
    bench.cols(["10", "100", "1000", "10000"]);

    let key : Blob = "\14\C9\72\09\03\D4\D5\72\82\95\E5\43\AF\FA\A9\44\49\2F\25\56\13\F3\6E\C7\B0\87\DC\76\08\69\14\CF";
    let nonce : Blob = "\E5\43\AF\FA\A9\44\49\2F\25\56\13\F3";
    let cipherRounds = 12;

    bench.runner(func(row, col) {
        let ?n = Nat.fromText(col);

        if (row == "0-255") {
          let RNG = ChaChaRNG.RNG(key, nonce, cipherRounds);
          ignore RNG.getRandomBytes(n)
        } else if (row == "0–65.5K") {
          let RNG = ChaChaRNG.RNG(key, nonce, cipherRounds);
          ignore RNG.getRandomNumbers(0, 65_500, n)
        } else if (row == "0–16.7M") {
          let RNG = ChaChaRNG.RNG(key, nonce, cipherRounds);
          ignore RNG.getRandomNumbers(0, 16_700_000, n)
        } else if (row == "0–4.2B") {
          let RNG = ChaChaRNG.RNG(key, nonce, cipherRounds);
          ignore RNG.getRandomNumbers(0, 4_200_000_000, n)
        } else if (row == "0-1.09T") {
          let RNG = ChaChaRNG.RNG(key, nonce, cipherRounds);
          ignore RNG.getRandomNumbers(0, 1_090_000_000_000, n)
        } else if (row == "0-281T") {
          let RNG = ChaChaRNG.RNG(key, nonce, cipherRounds);
          ignore RNG.getRandomNumbers(0, 281_000_000_000_000, n)
        } else if (row == "0–72Qa") {
          let RNG = ChaChaRNG.RNG(key, nonce, cipherRounds);
          ignore RNG.getRandomNumbers(0, 72_000_000_000_000_000, n)
        } else if (row == "0–18.4Qi") {
          let RNG = ChaChaRNG.RNG(key, nonce, cipherRounds);
          ignore RNG.getRandomNumbers(0, 18_400_000_000_000_000_000, n)
        }
      }
    );

    bench
  }
}
