// swiftlint:disable function_body_length

extension BigIntHeap {

  // MARK: - Sign

  // - sign of the result follows standard math rules:
  //   if the operands had the same sign then positive, otherwise negative
  // - sign of the remainder is the same `self` sign
  //
  // Based on following Swift code:
  // ```
  // let x = 10
  // let y = 3
  //
  // print(" \(x) /  \(y) =",   x  /   y,  "rem",   x  %   y)  //  10 /  3 =  3 rem  1
  // print(" \(x) / -\(y) =",   x  / (-y), "rem",   x  % (-y)) //  10 / -3 = -3 rem  1
  // print("-\(x) /  \(y) =", (-x) /   y,  "rem", (-x) %   y)  // -10 /  3 = -3 rem -1
  // print("-\(x) / -\(y) =", (-x) / (-y), "rem", (-x) % (-y)) // -10 / -3 =  3 rem -1
  // ```
  //
  // In Python remainder sign acts a bit differently.

  /// If the signs are the same then result is positive:
  /// `2/1 = 2` and also `(-2)*(-1) = 2`
  private func divIsNegative(otherIsNegative: Bool) -> Bool {
    return self.isNegative != otherIsNegative
  }

  /// Remainder will have the same sign as we have now.
  private func modIsNegative(otherIsNegative: Bool) -> Bool {
    return self.isNegative
  }

  // MARK: - Smi

  /// Returns remainder.
  internal mutating func div(other: Smi.Storage) -> Smi.Storage {
    defer { self.checkInvariants() }

    if other == -1 {
      self.negate() // x / (-1) = -x
      return .zero
    }

    let resultIsNegative = self.divIsNegative(otherIsNegative: other.isNegative)
    let remainderIsNegative = self.modIsNegative(otherIsNegative: other.isNegative)

    let word = Word(other.magnitude)
    let wordRemainder = self.div(other: word)

    self.storage.isNegative = resultIsNegative
    self.fixInvariants()

    // Remainder is always less than the number we divide by.
    // So even if we divide by min value (for example for 'Int8' it is -128),
    // the max possible remainder (127) is still representable in given type.
    assert(wordRemainder.isNegative == remainderIsNegative)
    let unsignedRemainder = Smi.Storage(wordRemainder.magnitude)
    return remainderIsNegative ? -unsignedRemainder : unsignedRemainder
  }

  internal struct DivWordRemainder {

    internal let isNegative: Bool
    internal let magnitude: Word

    internal var isPositive: Bool {
      return !self.isNegative
    }

    fileprivate static var zero: DivWordRemainder {
      return DivWordRemainder(isNegative: false, magnitude: 0)
    }
  }

  // MARK: - Word

  /// Returns remainder.
  internal mutating func div(other: Word) -> DivWordRemainder {
    defer { self.checkInvariants() }

    precondition(!other.isZero, "Division by zero")

    if other == 1 {
      return .zero // x / 1 = x
    }

    if self.isZero {
      return .zero // 0 / n = 0
    }

    let resultIsNegative = self.divIsNegative(otherIsNegative: false)
    let remainderIsNegative = self.modIsNegative(otherIsNegative: other.isNegative)

    switch Self.compareMagnitudes(lhs: self.storage, rhs: other) {
    case .equal: // 5 / 5 = 1 rem 0 and also 5 / (-5) = -1 rem 0
      self.storage.set(to: resultIsNegative ? -1 : 1)
      return .zero

    case .less: // 3 / 5 = 0 rem 3
      // Basically return 'self' as remainder
      assert(self.storage.count == 1)
      let unsignedRemainder = self.storage[0]
      self.storage.setToZero()
      return DivWordRemainder(isNegative: remainderIsNegative,
                              magnitude: unsignedRemainder)

    case .greater:
      let unsignedRemainder: Word = {
        // If 'smaller' is a power of 2 -> we can just shift right
        let otherLSB = other.trailingZeroBitCount
        let isOtherPowerOf2 = (other >> otherLSB) == 1
        if isOtherPowerOf2 {
          // Remainder - part we are 'chopping' off
          // (just like in Overcooked: chop, chop, chop)
          let remainderMask = ~(Word.max << otherLSB)
          let remainder = self.storage[0] & remainderMask
          self.shiftRight(count: otherLSB.magnitude)
          return remainder
        }

        var carry = Word.zero
        for i in (0..<self.storage.count).reversed() {
          let x = (high: carry, low: self.storage[i])
          (self.storage[i], carry) = other.dividingFullWidth(x)
        }

        return carry
      }()

      self.storage.isNegative = resultIsNegative
      self.fixInvariants()

      return DivWordRemainder(isNegative: remainderIsNegative,
                              magnitude: unsignedRemainder)
    }
  }

  // MARK: - Heap

  private static var zero: BigIntHeap {
    return BigIntHeap()
  }

  /// Returns remainder.
  internal mutating func div(other: BigIntHeap) -> BigIntHeap {
    defer { self.checkInvariants() }

    // Special case: other is '0', '1' or '-1'
    precondition(!other.isZero, "Division by zero")

    if other.hasMagnitudeOfOne {
      if other.isPositive {
        return .zero // x / 1 = x
      }

      assert(other.isNegative)
      self.negate() // x / (-1) = -x
      return .zero
    }

    // Special case: '0' divided by anything is '0'
    if self.isZero {
      return .zero
    }

    let resultIsNegative = self.divIsNegative(otherIsNegative: other.isNegative)
    let remainderIsNegative = self.modIsNegative(otherIsNegative: other.isNegative)

    switch Self.compareMagnitudes(lhs: self.storage, rhs: other.storage) {
    case .equal: // 5 / 5 = 1 rem 0 and also 5 / (-5) = -1 rem 0
      let value = self.storage.isNegative ? -1 : 1
      self.storage.set(to: value)
      return .zero

    case .less: // 3 / 5 = 0 rem 3
      // Basically return 'self' as remainder
      // We have to do a little dance to avoid COW.
      var remainder = self
      self.storage.setToZero()
      remainder.storage.isNegative = remainderIsNegative
      return remainder

    case .greater:
      // Oh no! We have to implement proper div logic!

      var selfCopy = self
      var quotient = BigIntHeap.zero
      let n = selfCopy.bitWidth - other.bitWidth

      var otherCopy = other
      otherCopy.shiftLeft(count: Smi.Storage(n))

      var quotientTmp = BigIntHeap(1)
      quotientTmp.shiftLeft(count: Smi.Storage(n))

      for _ in (0...n).reversed() {
        switch Self.compareMagnitudes(lhs: selfCopy.storage, rhs: otherCopy.storage) {
        case .greater:
          selfCopy.sub(other: otherCopy)
          quotient.add(other: quotientTmp)
        case .equal,
             .less:
          break
        }

        otherCopy.shiftRight(count: Smi.Storage(1))
        quotientTmp.shiftRight(count: Smi.Storage(1))
      }

      // 'selfCopy' is the remainder - match sign of original `self`
      selfCopy.storage.isNegative = remainderIsNegative
      selfCopy.storage.fixInvariants()

      // Again, COW dance
      quotient.storage.isNegative = resultIsNegative
      quotient.fixInvariants()
      self = quotient

      return selfCopy
    }
  }

  // TODO: Mod
  // TODO: Div mod
}
