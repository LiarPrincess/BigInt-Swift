extension BigIntHeap {

  // MARK: - Smi

  // TODO: Recheck all of the uses of 'checkInvariants'
  internal mutating func mul(other: Smi.Storage) {
    if other == -1 {
      self.negate()
      return
    }

    // If the signs are the same then we are positive.
    // '1 * 2 = 2' and also '(-1) * (-2) = 2'
    let resultIsNegative = self.isNegative != other.isNegative

    let word = Word(other.magnitude)
    self.mul(other: word)

    self.storage.isNegative = resultIsNegative
    self.fixInvariants()
  }

  // MARK: - Word

  internal mutating func mul(other: Word) {
    // Special cases for 'other': 0, 1
    if other.isZero {
      self.setToZero()
      return
    }

    if other == 1 {
      return
    }

    // Special cases for 'self': 0, 1, -1:
    if self.isZero {
      return
    }

    // Sign stays the same: 1 * x = x, -1 * x = -x (we know that x > 0)
    let preserveIsNegative = self.isNegative

    if self.hasMagnitudeOfOne {
      self.set(to: other)
      self.storage.isNegative = preserveIsNegative
      self.fixInvariants()
      return
    }

    // And finally non-special case:
    Self.mulMagnitude(lhs: &self, rhs: other)

    self.storage.isNegative = preserveIsNegative
    self.fixInvariants()
  }

  internal static func mulMagnitude(lhs: inout BigIntHeap, rhs: Word) {
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
    for i in 0..<lhs.storage.count {
      let (high, low) = lhs.storage[i].multipliedFullWidth(by: rhs)
      (carry, lhs.storage[i]) = low.addingFullWidth(carry)
      carry = carry &+ high
    }

    // Add the leftover carry
    if carry != 0 {
      lhs.storage.append(carry)
    }
  }

  // MARK: - Heap

  internal mutating func mul(other: BigIntHeap) {
    defer { self.checkInvariants() }

    // Special cases for 'other': 0, 1, -1
    if other.isZero {
      self.setToZero()
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
    Self.mulMagnitude(lhs: &self, rhs: other)
    self.storage.isNegative = self.isNegative != other.isNegative
    self.fixInvariants()
  }

  /// Will NOT look at the sign of any of those numbers!
  /// Only at the magnitude.
  ///
  /// We will be using school algorithm (`complexity: O(n^2)`):
  /// ```
  ///      2013 <- bigger
  ///    * 2019 <- smaller
  ///    ------
  ///     18117 <- inner loop for 'smallerWord = 9'
  ///     2013
  ///       0
  /// + 4026
  /// ---------
  ///   4064247 <- this is result
  /// ```.
  internal static func mulMagnitude(lhs: inout BigIntHeap, rhs: BigIntHeap) {
    let resultCount = lhs.storage.count + rhs.storage.count
    var result = BigIntStorage(repeating: 0, count: resultCount)
    result.isNegative = lhs.isNegative

    // We will use 'smaller' for inner loop in hope that it will generate
    // smaller pressure on registers.
    let (smaller, bigger) = lhs.storage.count <= rhs.storage.count ?
      (lhs, rhs) :
      (rhs, lhs)

    for biggerIndex in 0..<bigger.storage.count {
      var carry = Word.zero
      let biggerWord = bigger.storage[biggerIndex]

      for smallerIndex in 0..<smaller.storage.count {
        let smallerWord = smaller.storage[smallerIndex]
        let resultIndex = biggerIndex + smallerIndex

        let (high, low) = biggerWord.multipliedFullWidth(by: smallerWord)
        (carry, result[resultIndex]) = result[resultIndex].addingFullWidth(low, carry)

        // Let's deal with 'high' in the next iteration.
        // No overflow possible (we have unit test for this).
        carry += high
      }

      // Last operation ('mul' or 'add') produced overflow.
      // We can just add it in the right place.
      result[biggerIndex + smaller.storage.count] += carry
    }

    lhs = BigIntHeap(storage: result)
  }
}
