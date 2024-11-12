import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

module {
  public class RNG(keyBlob : Blob, nonceBlob : Blob, roundCount : Nat) {
    assert keyBlob.size() >= 32;
    assert nonceBlob.size() >= 12;
    assert roundCount >= 8 and roundCount <= 20;

    func BlobToNat32Array(b : Blob) : [Nat32] {
      let bytes = Blob.toArray(b);
      let length = bytes.size() / 4;

      Array.tabulate<Nat32>(length, func(i) {
          let index = i * 4;
          (Nat32.fromNat(Nat8.toNat(bytes[index])) << 24) +
          (Nat32.fromNat(Nat8.toNat(bytes[index + 1])) << 16) +
          (Nat32.fromNat(Nat8.toNat(bytes[index + 2])) << 8) +
          Nat32.fromNat(Nat8.toNat(bytes[index + 3]))
      });
    };

    let key = BlobToNat32Array(keyBlob);
    let nonce = BlobToNat32Array(nonceBlob);

    let baseState : [Nat32] = [
      0x61707865, 0x3320646E, 0x79622D32, 0x6B206574,
      key[0], key[1], key[2], key[3],
      key[4], key[5], key[6], key[7],
      1,  nonce[0],  nonce[1],  nonce[2]
    ];

    let byteBuffer : [var Nat8] = Array.init<Nat8>(64, 0);
    var bufferIndex : Nat = 64; // Start with byteBuffer needing refill
    var stateCounter : Nat32 = 1;

    func quarterRound(state: [var Nat32], a: Nat, b: Nat, c: Nat, d: Nat) {
      state[a] +%= state[b];  state[d] ^= state[a]; state[d] <<>= 16;
      state[c] +%= state[d];  state[b] ^= state[c]; state[b] <<>= 12;
      state[a] +%= state[b];  state[d] ^= state[a]; state[d] <<>= 8;
      state[c] +%= state[d];  state[b] ^= state[c]; state[b] <<>= 7
    };

    func chachaBlock() {
      let workingState = Array.tabulateVar<Nat32>(baseState.size(), func(i) { baseState[i] });
      workingState[12] := stateCounter;
      stateCounter +%= 1;

      // Apply the ChaCha rounds to the workingState
      for (i in Iter.range(0, roundCount / 2 - 1)) {
        // Column round
        quarterRound(workingState, 0, 4, 8, 12);
        quarterRound(workingState, 1, 5, 9, 13);
        quarterRound(workingState, 2, 6, 10, 14);
        quarterRound(workingState, 3, 7, 11, 15);

        // Diagonal round
        quarterRound(workingState, 0, 5, 10, 15);
        quarterRound(workingState, 1, 6, 11, 12);
        quarterRound(workingState, 2, 7, 8, 13);
        quarterRound(workingState, 3, 4, 9, 14);
      };

      for (i in Iter.range(0, 15)) {
        // Final addition with baseState
        workingState[i] +%= baseState[i];

        // Store in byteBuffer
        let currentState = workingState[i];
        byteBuffer[4 * i] := Nat8.fromIntWrap(Nat32.toNat(currentState >> 24));
        byteBuffer[4 * i + 1] := Nat8.fromIntWrap(Nat32.toNat(currentState >> 16));
        byteBuffer[4 * i + 2] := Nat8.fromIntWrap(Nat32.toNat(currentState >> 8));
        byteBuffer[4 * i + 3] := Nat8.fromIntWrap(Nat32.toNat(currentState));
      };
    };

    public func getRandomBytes(byteCount : Nat) : [Nat8] {
      let result : [var Nat8] = Array.init<Nat8>(byteCount, 0);
      var index : Nat = 0;

      while (index < byteCount) {
        // Refill byteBuffer if exhausted
        if (bufferIndex >= 64) {
          chachaBlock();
          bufferIndex := 0;
        };

        // Copy from byteBuffer
        let take = Nat.min(byteCount - index, 64 - bufferIndex);
        for (i in Iter.range(0, take - 1)) {
          result[index + i] := byteBuffer[bufferIndex + i];
        };
        bufferIndex := bufferIndex + take;
        index := index + take;
      };

      return Array.freeze<Nat8>(result);
    };

    public func getRandomNumber(min : Nat64, max : Nat64) : Nat {
      let rangeSize = max - min;
      if (rangeSize <= 0) return Nat64.toNat(min);

      let (byteCount, bitMask) = calculateByteCountBitMask(rangeSize);
      return Nat64.toNat(min + generateNumber(rangeSize, byteCount, bitMask))
    };

    public func getRandomNumbers(min : Nat64, max : Nat64, count : Nat) : [Nat] {
      if (count == 0) return [];
      let rangeSize = max - min;
      if (rangeSize <= 0) return [Nat64.toNat(min)];

      let (byteCount, bitMask) = calculateByteCountBitMask(rangeSize);
      return Array.tabulate<Nat>(count, func(_) {
          Nat64.toNat(min + generateNumber(rangeSize, byteCount, bitMask))
      });
    };

    func calculateByteCountBitMask(rangeSize : Nat64) : (Nat, Nat64) {
      let bitCount = 64 - Nat64.bitcountLeadingZero(rangeSize);
      let byteCount = Nat64.toNat((bitCount + 7) >> 3);
      let bitMask = (1 << bitCount) - 1;
      return (byteCount, bitMask);
    };

    func generateNumber(rangeSize : Nat64, byteCount : Nat, bitMask : Nat64) : Nat64 {
      // Using rejection sampling to avoid bias
      loop {
        let bytes = getRandomBytes(byteCount);
        var number : Nat64 = 0;
        for (byte in bytes.vals()) number := (number << 8) | Nat64.fromNat(Nat8.toNat(byte)); //convert bytes to Nat64 number
        number &= bitMask; // Discard extra bits beyond the required bit range
        if (number <= rangeSize) return number;
      };
    };
  };
};
