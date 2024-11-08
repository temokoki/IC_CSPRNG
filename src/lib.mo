import Blob "mo:base/Blob";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

module {
  public class RNG(keyBlob : Blob, nonceBlob : Blob, roundCount : Nat) {
    assert keyBlob.size() >= 32;
    assert nonceBlob.size() >= 12;
    assert roundCount >= 8 and roundCount <= 20;

    //----- Utility functions -----
    func BlobToNat32Array(b : Blob) : [Nat32] {
      let bytes = Blob.toArray(b);
      let length = bytes.size() / 4;

      Array.tabulate<Nat32>(length, func(i) {
        let index = i * 4;
        Nat32FromBytes([bytes[index], bytes[index + 1], bytes[index + 2], bytes[index + 3]])
      });
    };

    func Nat32FromBytes(bytes : [Nat8]) : Nat32 {
      var result : Nat32 = 0;
      for (i in Iter.range(0, bytes.size() - 1)) {
        result := (result << 8) + Nat16.toNat32(Nat16.fromNat8(bytes[i]));
      };
      return result;
    };

    func NatFromBytes(bytes : [Nat8]) : Nat {
      var result : Nat = 0;
      for (i in Iter.range(0, bytes.size() - 1)) {
        result := Nat.bitshiftLeft(result, 8) + Nat8.toNat(bytes[i]);
      };
      return result;
    };
    //-----------------------------

    let key = BlobToNat32Array(keyBlob);
    let nonce = BlobToNat32Array(keyBlob);

    let baseState : [Nat32] = [
      0x61707865, 0x3320646E, 0x79622D32, 0x6B206574,
      key[0], key[1], key[2], key[3],
      key[4], key[5], key[6], key[7],
      0,  nonce[0],  nonce[1],  nonce[2]
    ];

    let byteBuffer : [var Nat8] = Array.init<Nat8>(64, 0);
    var bufferIndex : Nat = 64; // Start with byteBuffer needing refill
    var stateCounter : Nat32 = 0;

    func quarterRound(state: [var Nat32], a: Nat, b: Nat, c: Nat, d: Nat) {
      state[a] +%= state[b];  state[d] ^= state[a]; state[d] <<>= 16;
      state[c] +%= state[d];  state[b] ^= state[c]; state[b] <<>= 12;
      state[a] +%= state[b];  state[d] ^= state[a]; state[d] <<>= 8;
      state[c] +%= state[d];  state[b] ^= state[c]; state[b] <<>= 7
    };

    func chachaBlock() {
      let workingState = Array.tabulateVar<Nat32>(baseState.size(), func(i) { baseState[i] });
      workingState[12] := stateCounter;
      stateCounter += 1;

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

      bufferIndex := 0;
    };

    public func getRandomBytes(byteCount : Nat) : [Nat8] {
      let result : [var Nat8] = Array.init<Nat8>(byteCount, 0);
      var index : Nat = 0;

      while (index < byteCount) {
        // Refill byteBuffer if exhausted
        if (bufferIndex >= 64) {
          chachaBlock();
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

    public func getRandomNumber(min : Nat, max : Nat) : Nat {
      assert (max > min);
      let rangeSize = max - min + 1;

      // Determine the minimum number of bytes needed to represent the range size
      let byteCount = if (rangeSize <= 0xFF) { 1 }
                    else if (rangeSize <= 0xFFFF) { 2 }
                    else if (rangeSize <= 0xFFFFFF) { 3 }
                    else if (rangeSize <= 0xFFFFFFFF) { 4 }
                    else if (rangeSize <= 0xFFFFFFFFFF) { 5 }
                    else if (rangeSize <= 0xFFFFFFFFFFFF) { 6 }
                    else if (rangeSize <= 0xFFFFFFFFFFFFFF) { 7 }
                    else { 8 };

    
      let number = NatFromBytes(getRandomBytes(byteCount));
      return min + (number % rangeSize);
    };

    public func getRandomNumbers(min : Nat, max : Nat, count : Nat) : [Nat] {
      Array.tabulate<Nat>(count, func(_) { getRandomNumber(min, max) });
    };
  };
};
