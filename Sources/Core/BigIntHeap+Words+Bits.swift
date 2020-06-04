extension BigIntHeap {

  // MARK: - Words

  internal var words: BigIntStorage {
    return self.asTwoComplement()
  }

  // MARK: - Bit width

  /// The minimum number of bits required to represent this integer in binary.
  internal var bitWidth: Int {
    guard let last = self.storage.last else {
      assert(self.isZero)
      return 0
    }

    let sign = 1
    return self.storage.count * Word.bitWidth - last.leadingZeroBitCount + sign
  }

  internal var minRequiredWidth: Int {
    return self.bitWidth
  }

  // MARK: - Trailing zero bit count

  /// The number of trailing zero bits in the binary representation of this integer.
  ///
  /// - Important:
  /// `0` is considered to have zero trailing zero bits.
  internal var trailingZeroBitCount: Int {
    if let index = self.storage.lastIndex(where: { $0 != 0 }) {
      let word = self.storage[index]
      return index * Word.bitWidth + word.trailingZeroBitCount
    }

    assert(self.isZero)
    return 0
  }
}
