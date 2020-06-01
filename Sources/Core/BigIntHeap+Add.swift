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
    self.storage.fixInvariants()
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
}
