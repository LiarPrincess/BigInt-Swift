extension BigIntHeap {

  // MARK: - Words

  internal var words: BigIntStorage {
    // We will return 'BigIntStorage' to save allocation in some cases.
    // But remember that in this case it will be used as collection,
    // that means that eny additional data (sign etc.) will be ignored.

    if self.isZero {
      return self.storage
    }

    if self.isPositive {
      // If we start with '1' then we have to add artificial '0' in front.
      // This does not happen very often.
      if let last = self.storage.last, last >> (Word.bitWidth - 1) == 1 {
        var copy = self.storage
        copy.append(0)
        return copy
      }

      return self.storage
    }

    assert(self.isNegative)

    // At this point our 'storage' holds positive number,
    // so we have force 2 complement.
    var copy = self.storage
    copy.transformEveryWord(fn: ~) // Invert every word
    Self.addMagnitude(lhs: &copy, rhs: 1)
    return copy
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
