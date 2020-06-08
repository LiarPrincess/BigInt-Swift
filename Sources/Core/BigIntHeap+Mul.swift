extension BigIntHeap {

  // MARK: - Smi

  internal mutating func mul(other: Smi.Storage) {
    defer { self.checkInvariants() }

    // Special cases for 'other': 0, 1, -1
    if other.isZero {
      self.storage.setToZero()
      return
    }

    if other == 1 {
      return
    }

    if other == -1 {
      self.negate()
      return
    }

    // Special cases for 'self': 0, 1, -1:
    if self.isZero {
      return
    }

    if self.hasMagnitudeOfOne {
      // If we are negative then result should have opposite sign than 'other'.
      // Remember to cast 'other' to 'Int' before changing sign,
      // because '-Smi.Storage.min' overflows.
      let value = self.isNegative ? -Int(other) : Int(other)
      self.storage.set(to: value)
      return
    }

    // But wait, there is more:
    // if 'other' is a power of 2 -> we can just shift left
    let otherLSB = other.trailingZeroBitCount
    let isOtherPowerOf2 = (other >> otherLSB) == 1
    if isOtherPowerOf2 {
      self.shiftLeft(count: otherLSB.magnitude)
      return
    }

    // And finally non-special case:

    // Just using '-' may overflow!
    let word = Word(other.magnitude)
    Self.mulMagnitude(lhs: &self.storage, rhs: word)

    // If the signs are the same then we are positive.
    // '1 * 2 = 2' and also (-1) * (-2) = 2
    self.storage.isNegative = self.isNegative != other.isNegative
    self.fixInvariants()
  }

  internal static func mulMagnitude(lhs: inout BigIntStorage, rhs: Word) {
    if rhs.isZero {
      lhs.setToZero()
      return
    }

    if lhs.isZero {
      return
    }

    if rhs == 1 {
      return
    }

    var carry: Word = 0
    for i in 0..<lhs.count {
      let (high, low) = lhs[i].multipliedFullWidth(by: rhs)
      (carry, lhs[i]) = low.addingFullWidth(carry)
      carry = carry &+ high
    }

    // Add the leftover carry
    if carry != 0 {
      lhs.append(carry)
    }
  }

  // MARK: - Heap

  internal mutating func mul(other: BigIntHeap) {
    defer { self.checkInvariants() }

    // Special cases for 'other': 0, 1, -1
    if other.isZero {
      self.storage.setToZero()
      return
    }

    if other.hasMagnitudeOfOne {
      if other.isNegative {
        self.negate()
      }

      return
    }

    // Special cases for 'self': 0, 1, -1:
    if self.isZero {
      return
    }

    if self.hasMagnitudeOfOne {
      let changeSign = self.isNegative
      self.storage = other.storage

      if changeSign {
        self.negate()
      }

      return
    }

    // And finally non-special case:
    // If the signs are the same then we are positive.
    // '1 * 2 = 2' and also (-1) * (-2) = 2
    Self.mulMagnitude(lhs: &self.storage, rhs: other.storage)
    self.storage.isNegative = self.isNegative != other.isNegative
    self.fixInvariants()
  }

  /// Will NOT look at the sign of any of those numbers!
  /// Only at the magnitude.
  ///
  /// We will be using school algorithm (`complexity: O(n^2)`):
  /// ```
  ///      2013 <- lhs
  ///    * 2019 <- rhs
  ///    ------
  ///     18117 <- this is row (lhs: 2013, rhs: 9)
  ///     2013
  ///       0
  /// + 4026
  /// ---------
  ///   4064247 <- this is acc
  /// ```.
  internal static func mulMagnitude(lhs: inout BigIntStorage, rhs: BigIntStorage) {
    let resultCount = lhs.count + rhs.count
    var result = BigIntStorage(repeating: 0, count: resultCount)

    // We will use 'smaller' for inner loop in hope that it will generate
    // smaller pressure on registers.
    let (smaller, bigger) = lhs.count <= rhs.count ? (lhs, rhs) : (rhs, lhs)

    for biggerIndex in 0..<bigger.count {
      var carry = Word.zero
      let biggerWord = bigger[biggerIndex]

      if biggerWord.isZero {
        continue
      }

      for smallerIndex in 0..<smaller.count {
        let smallerWord = smaller[smallerIndex]
        let resultIndex = biggerIndex + smallerIndex

        let (high, low) = biggerWord.multipliedFullWidth(by: smallerWord)
        (carry, result[resultIndex]) = result[resultIndex].addingFullWidth(low, carry)

        // TODO: Unit test for lack of overflow (99 99 99 * 99 99)
        // Let's deal with 'high' in the next iteration.
        carry += high
      }

      // Last operation ('mul' or 'add') produced overflow.
      // We can just add it in the right place.
      result[biggerIndex + smaller.count] += carry
    }

    lhs = result
  }
}
