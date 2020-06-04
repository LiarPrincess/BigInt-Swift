// swiftlint:disable function_body_length
// swiftlint:disable file_length

// Most of the code was taken from: https://gmplib.org
// GMP function name is in comment obove method name.

// MARK: - Helper extensions

// Implement missing pieces from 'C' integer api.

extension Bool {

  fileprivate var asWord: BigIntStorage.Word {
    return self ? 1 : 0
  }
}

extension BigIntStorage.Word {

  fileprivate var isTrue: Bool {
    return self != 0
  }

  /// This implements `-` before unsigned number.
  ///
  /// It works this way:
  /// - if it is `0` -> stay `0`
  /// - otherwise -> `MAX - x + 1`, so in our case `MAX - 1 + 1 = MAX`
  fileprivate var allOneIfTrueOtherwiseAllZero: BigIntStorage.Word {
    return self.isTrue ? Self.max : Self.zero
  }
}

extension BigIntHeap {

  // MARK: - Negate

  internal mutating func negate() {
    // Zero is always positive
    if self.isZero {
      assert(self.isPositive)
      return
    }

    self.storage.isNegative.toggle()
    self.checkInvariants()
  }

  // MARK: - Invert

  /// void
  /// mpz_com (mpz_t r, const mpz_t u)
  internal mutating func invert() {
    self.add(other: 1)
    self.negate()
    self.checkInvariants()
  }

  // MARK: - And

  /// void
  /// mpz_and (mpz_t r, const mpz_t u, const mpz_t v)
  ///
  /// Variable names mostly taken from GMP.
  internal mutating func and(other: BigIntHeap) {
    if self.isZero {
      return
    }

    if other.isZero {
      self.storage.setToZero()
      return
    }

    // 'v' is smaller, 'u' is bigger
    let v = self.storage.count <= other.storage.count ? self.storage : other.storage
    let u = self.storage.count <= other.storage.count ? other.storage : self.storage
    assert(v.count <= u.count)

    var vIsNegative = v.isNegative.asWord
    var uIsNegative = u.isNegative.asWord
    var bothNegative = vIsNegative & uIsNegative

    let vMask = vIsNegative.allOneIfTrueOtherwiseAllZero
    let uMask = uIsNegative.allOneIfTrueOtherwiseAllZero
    let bothNegativeMask = bothNegative.allOneIfTrueOtherwiseAllZero

    // If the smaller input is positive, higher words don't matter.
    let resultCount = v.isPositive ? v.count : u.count
    var result = BigIntStorage(repeating: 0, count: resultCount + Int(bothNegative))

    for i in 0..<v.count {
      let ul = (u[i] ^ uMask) + uIsNegative
      uIsNegative = (ul < uIsNegative).asWord

      let vl = (v[i] ^ vMask) + vIsNegative
      vIsNegative = (vl < vIsNegative).asWord

      let rl = ((ul & vl) ^ bothNegativeMask) + bothNegative
      bothNegative = (rl < bothNegative).asWord

      result[i] = rl
    }

    assert(vIsNegative == 0)

    for i in v.count..<resultCount {
      let ul = (u[i] ^ uMask) + uIsNegative
      uIsNegative = (ul < uIsNegative).asWord

      let rl = ( (ul & vMask) ^ bothNegativeMask) + bothNegative
      bothNegative = (rl < bothNegative).asWord

      result[i] = rl
    }

    if bothNegative.isTrue {
      result[resultCount] = bothNegative
    }

    result.isNegative = bothNegative.isTrue
    result.fixInvariants()
    self.storage = result
  }

  // MARK: - Or

  /// void
  /// mpz_ior (mpz_t r, const mpz_t u, const mpz_t v)
  ///
  /// Variable names mostly taken from GMP.
  internal mutating func or(other: BigIntHeap) {
    if self.isZero {
      self.storage = other.storage
      return
    }

    if other.isZero {
      return
    }

    // 'v' is smaller, 'u' is bigger
    let v = self.storage.count <= other.storage.count ? self.storage : other.storage
    let u = self.storage.count <= other.storage.count ? other.storage : self.storage
    assert(v.count <= u.count)

    var vIsNegative = v.isNegative.asWord
    var uIsNegative = u.isNegative.asWord
    var anyNegative = vIsNegative | uIsNegative

    let vMask = vIsNegative.allOneIfTrueOtherwiseAllZero
    let uMask = uIsNegative.allOneIfTrueOtherwiseAllZero
    let anyNegativeMask = anyNegative.allOneIfTrueOtherwiseAllZero

    // If the smaller input is negative, by sign extension higher words don't matter.
    let resultCount = vMask.isTrue ? v.count : u.count
    var result = BigIntStorage(repeating: 0, count: resultCount + Int(anyNegative))

    for i in 0..<v.count {
      let ul = (u[i] ^ uMask) + uIsNegative
      uIsNegative = (ul < uIsNegative).asWord

      let vl = (v[i] ^ vMask) + vIsNegative
      vIsNegative = (vl < vIsNegative).asWord

      let rl = ((ul | vl) ^ anyNegativeMask) + anyNegative
      anyNegative = (rl < anyNegative).asWord

      result[i] = rl
    }

    assert(vIsNegative == 0)

    for i in v.count..<resultCount {
      let ul = (u[i] ^ uMask) + uIsNegative
      uIsNegative = (ul < uIsNegative).asWord

      let rl = ( (ul | vMask) ^ anyNegativeMask) + anyNegative
      anyNegative = (rl < anyNegative).asWord

      result[i] = rl
    }

    if anyNegative.isTrue {
      result[resultCount] = anyNegative
    }

    result.isNegative = anyNegative.isTrue
    result.fixInvariants()
    self.storage = result
  }

  // MARK: - Xor

  /// void
  /// mpz_xor (mpz_t r, const mpz_t u, const mpz_t v)
  ///
  /// Variable names mostly taken from GMP.
  internal mutating func xor(other: BigIntHeap) {
    if self.isZero {
      self.storage = other.storage
      return
    }

    if other.isZero {
      return
    }

    // 'v' is smaller, 'u' is bigger
    let v = self.storage.count <= other.storage.count ? self.storage : other.storage
    let u = self.storage.count <= other.storage.count ? other.storage : self.storage
    assert(v.count <= u.count)

    var vIsNegative = v.isNegative.asWord
    var uIsNegative = u.isNegative.asWord
    var onlyOneNegative = vIsNegative ^ uIsNegative

    let vMask = vIsNegative.allOneIfTrueOtherwiseAllZero
    let uMask = uIsNegative.allOneIfTrueOtherwiseAllZero
    let onlyOneNegativeMask = onlyOneNegative.allOneIfTrueOtherwiseAllZero

    let resultCount = u.count
    var result = BigIntStorage(repeating: 0, count: resultCount + Int(onlyOneNegative))

    for i in 0..<v.count {
      let ul = (u[i] ^ uMask) + uIsNegative
      uIsNegative = (ul < uIsNegative).asWord

      let vl = (v[i] ^ vMask) + vIsNegative
      vIsNegative = (vl < vIsNegative).asWord

      let rl = (ul ^ vl ^ onlyOneNegativeMask) + onlyOneNegative
      onlyOneNegative = (rl < onlyOneNegative).asWord

      result[i] = rl
    }

    assert(vIsNegative == 0)

    for i in v.count..<resultCount {
      let ul = (u[i] ^ uMask) + uIsNegative
      uIsNegative = (ul < uIsNegative).asWord

      let rl = (ul ^ uMask) + onlyOneNegative
      onlyOneNegative = (rl < onlyOneNegative).asWord

      result[i] = rl
    }

    if onlyOneNegative.isTrue {
      result[resultCount] = onlyOneNegative
    }

    result.isNegative = onlyOneNegative.isTrue
    result.fixInvariants()
    self.storage = result
  }

  // MARK: - Two complement

  /// `inout` to avoid copy.
  internal init(twoComplement: inout BigIntStorage) {
    // Check for '0'
    guard let last = twoComplement.last else {
      self.init()
      return
    }

    let isPositive = last >> (Word.bitWidth - 1) == 0
    if isPositive {
      twoComplement.isNegative = false
    } else {
      // For negative numbers we have to revert 2 complement.
      twoComplement.isNegative = true
      twoComplement.transformEveryWord(fn: ~) // Invert every word
      Self.addMagnitude(lhs: &twoComplement, rhs: 1)
    }

    // 'fixInvariants' BEFORE 'init' to avoid COW!
    twoComplement.fixInvariants()
    self.init(storage: twoComplement)
  }

  /// We will return 'BigIntStorage' to save allocation in some cases.
  ///
  /// But remember that in this case it will be used as collection,
  /// that means that eny additional data (sign etc.) should be ignored.
  internal func asTwoComplement() -> BigIntStorage {
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
}
