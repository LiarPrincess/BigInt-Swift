extension BigIntHeap {

  // MARK: - Smi

  internal mutating func add(other: Smi.Storage) {
    if other.isZero {
      return
    }

    // We are in for non-trivial case:
    defer { self.checkInvariants() }

    // Just using '-' may overflow!
    let word = Word(other.magnitude)

    if self.isZero {
      self.storage.append(word)
      return
    }

    // If we have the same sign then we can simply add magnitude.
    if self.isPositive == other.isPositive {
      Self.addMagnitude(lhs: &self.storage, rhs: word)
      return
    }

    // Self positive, other negative: x + (-y) = x - y
    if self.isPositive {
      assert(other.isNegative)
      self.sub(other: word)
      return
    }

    // Self negative, other positive:  -x + y = -(x - y)
    assert(self.isNegative && other.isPositive)
    self.negate() // -x -> x
    self.sub(other: word) // x - y
    self.negate() // -(x - y)
    self.fixInvariants()
  }

  internal static func addMagnitude(lhs: inout BigIntStorage, rhs: Word) {
    if rhs.isZero {
      return
    }

    if lhs.isEmpty {
      lhs.append(rhs)
      return
    }

    var carry: Word
    (carry, lhs[0]) = lhs[0].addingFullWidth(rhs)

    for i in 1..<lhs.count {
      guard carry > 0 else {
        break
      }

      (carry, lhs[i]) = lhs[i].addingFullWidth(carry)
    }

    if carry > 0 {
      lhs.append(1)
    }
  }

  // MARK: - Heap

  internal mutating func add(other: BigIntHeap) {
    if other.isZero {
      return
    }

    // We are in for non-trivial case:
    defer { self.checkInvariants() }

    if self.isZero {
      self.storage = other.storage
      return
    }

    // If we have the same sign then we can simply add magnitude.
    if self.isPositive == other.isPositive {
      Self.addMagnitudes(lhs: &self.storage, rhs: other.storage)
      return
    }

    // Self positive, other negative: x + (-y) = x - y
    if self.isPositive {
      assert(other.isNegative)
      var otherPositive = other
      otherPositive.storage.isNegative = false
      self.sub(other: otherPositive)
      return
    }

    // Self negative, other positive:  -x + y = -(x - y)
    assert(self.isNegative && other.isPositive)
    self.negate() // -x -> x
    self.sub(other: other) // x - y
    self.negate() // -(x - y)
    self.fixInvariants()
  }

  /// Will NOT look at the sign of any of those numbers!
  /// Only at the magnitude.
  internal static func addMagnitudes(lhs: inout BigIntStorage,
                                     rhs: BigIntStorage) {
    if rhs.isZero {
      return
    }

    if lhs.isZero {
      lhs = rhs
      return
    }

    let commonCount = Swift.min(lhs.count, rhs.count)
    let maxCount = Swift.max(lhs.count, rhs.count)
    lhs.reserveCapacity(maxCount)

    // Add the words up to the common count, carrying any overflows
    var carry: Word = 0
    for i in 0..<commonCount {
      (carry, lhs[i]) = lhs[i].addingFullWidth(rhs[i], carry)
    }

    // If there are leftover words in 'lhs', just need to handle any carries
    if lhs.count > rhs.count {
      for i in commonCount..<maxCount {
        if carry == 0 {
          break
        }

        (carry, lhs[i]) = lhs[i].addingFullWidth(carry)
      }
    }
    // If there are leftover words in 'rhs', need to copy to 'lhs' with carries
    else {
      for i in commonCount..<maxCount {
        // Append remaining words if nothing to carry
        if carry == 0 {
          lhs.append(contentsOf: rhs.suffix(from: i))
          break
        }

        let word: Word
        (carry, word) = rhs[i].addingFullWidth(carry)
        lhs.append(word)
      }
    }

    // If there's any carry left, add it now
    if carry != 0 {
      lhs.append(1)
    }
  }
}
