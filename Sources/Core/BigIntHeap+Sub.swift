extension BigIntHeap {

  // MARK: - Smi

  internal mutating func sub(other: Smi.Storage) {
    if other.isZero {
      return
    }

    // We are in for non-trivial case:
    defer { self.checkInvariants() }

    // Just using '-' may overflow!
    let word = Word(other.magnitude)

    if self.isZero {
      self.storage.append(word)
      self.storage.isNegative = !other.isNegative
      return
    }

    // We can simply add magnitudes when:
    // - self.isNegative && other.isPositive (for example: -5 - 6 = -11)
    // - self.isPositive && other.isNegative (for example:  5 - (-6) = 5 + 6 = 11)
    // which is the same as:
    if self.isNegative != other.isNegative {
      Self.addMagnitude(lhs: &self.storage, rhs: word)
      return
    }

    // Both have the same sign, for example '1 - 1' or '-2 - (-3)'.
    // That means that we may need to cross 0.
    switch Self.compareMagnitudes(lhs: self.storage, rhs: word) {
    case .equal: // 1 - 1
      self.setToZero()

    case .less: // 1 - 2 = -(-1 + 2)  = -(2 - 1), we are changing sign
      let changedSign = !self.isNegative
      let result = word - self.storage[0]
      self.storage.set(to: result)
      self.storage.isNegative = changedSign

    case .greater: // 2 - 1, sign stays the same
      Self.subMagnitude(bigger: &self.storage, smaller: word)
    }
  }

  internal mutating func sub(other: Word) {
    fatalError()
  }

  private static func subMagnitude(bigger: inout BigIntStorage, smaller: Word) {
    if smaller.isZero {
      return
    }

    var carry: Word
    (carry, bigger[0]) = bigger[0].subtractingFullWidth(smaller)

    for i in 1..<bigger.count {
      if carry == 0 {
        break
      }

      (carry, bigger[i]) = bigger[i].subtractingFullWidth(carry)
    }

    assert(carry == 0, "bigger > smaller")
  }
}
