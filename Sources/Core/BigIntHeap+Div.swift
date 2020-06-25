// swiftlint:disable file_length

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

    switch self.compareMagnitude(with: other) {
    case .equal: // 5 / 5 = 1 rem 0 and also 5 / (-5) = -1 rem 0
      self.storage.set(to: resultIsNegative ? -1 : 1)
      return .zero

    case .less: // 3 / 5 = 0 rem 3
      // Basically return 'self' as remainder
      assert(self.storage.count == 1)
      let remainderMagnitude = self.storage[0]
      self.storage.setToZero()
      return DivWordRemainder(isNegative: remainderIsNegative,
                              magnitude: remainderMagnitude)

    case .greater:
      let remainderMagnitude = Self.divMagnitude(dividend: &self, divisor: other)

      self.storage.isNegative = resultIsNegative
      self.fixInvariants()

      return DivWordRemainder(isNegative: remainderIsNegative,
                              magnitude: remainderMagnitude)
    }
  }

  /// Returns remainder.
  ///
  /// Will NOT look at the sign of any of those numbers!
  /// Only at the magnitude.
  ///
  /// Precondition: `dividend > divisor`
  private static func divMagnitude(dividend: inout BigIntHeap,
                                   divisor: Word) -> Word {
    // Shifting right when 'other' is power of 2
    // would not work for negative numbers.

    var carry = Word.zero
    for i in (0..<dividend.storage.count).reversed() {
      let arg = (high: carry, low: dividend.storage[i])
      (dividend.storage[i], carry) = divisor.dividingFullWidth(arg)
    }

    return carry
  }

  // MARK: - Heap

  private static var zero: BigIntHeap {
    return BigIntHeap()
  }

  /// Returns remainder.
  internal mutating func div(other: BigIntHeap) -> BigIntHeap {
    defer { self.checkInvariants() }

    // Special cases: other is '0', '1' or '-1'
    precondition(!other.isZero, "Division by zero")

    if other.hasMagnitudeOfOne {
      if other.isPositive {
        return .zero // x / 1 = x rem 0
      }

      assert(other.isNegative)
      self.negate() // x / (-1) = -x rem 0
      return .zero
    }

    // Special case: '0' divided by anything is '0 rem 0'
    if self.isZero {
      return .zero
    }

    let resultIsNegative = self.divIsNegative(otherIsNegative: other.isNegative)
    let remainderIsNegative = self.modIsNegative(otherIsNegative: other.isNegative)

    switch self.compareMagnitude(with: other) {
    case .equal: // 5 / 5 = 1 rem 0 and also 5 / (-5) = -1 rem 0
      self.storage.set(to: resultIsNegative ? -1 : 1)
      return .zero

    case .less: // 3 / 5 = 0 rem 3
      // Basically return 'self' as remainder
      // We have to do a little dance to avoid COW.
      var remainder = self
      self.storage.setToZero() // Will use predefined 'BigIntStorage.zero' (COW)
      remainder.storage.isNegative = remainderIsNegative
      return remainder

    case .greater:
      // Oh no! We have to implement proper div logic!
      var remainder = Self.divMagnitude(dividend: &self, divisor: other)

      self.storage.isNegative = resultIsNegative
      self.fixInvariants()

      remainder.storage.isNegative = remainderIsNegative
      remainder.fixInvariants()
      return remainder
    }
  }

// swiftlint:disable function_body_length

  /// Returns remainder.
  ///
  /// Based on implementation in 'V8': 'src/objects/bigint.cc'.
  ///
  /// Will NOT look at the sign of any of those numbers!
  /// Only at the magnitude.
  private static func divMagnitude(dividend: inout BigIntHeap,
                                   divisor: BigIntHeap) -> BigIntHeap {
// swiftlint:enable function_body_length

    // Check for single word divisor, to quarantee 'n >= 2'
    if divisor.storage.count == 1 {
      let word = divisor.storage[0]
      let remainder = Self.divMagnitude(dividend: &dividend, divisor: word)
      return BigIntHeap(remainder.magnitude)
    }

    let n = divisor.storage.count
    let m = dividend.storage.count - n

    // Assuming that we already checked for '0'
    assert(m >= 0)
    assert(n >= 2) // We checked for 'divisor.storage.count == 1'
    assert(Word.bitWidth == 64) // Other not tested

    // D1.
    // Left-shift inputs so that the divisor's MSB is '1'.
    // Note that: 'a / b = (a * n) / (b * n)'
    let shift = divisor.storage[divisor.storage.count].leadingZeroBitCount

    /// This is the correct value that should be used during calculation!
    let shiftedDivisor = Self.specialLeftShift(value: divisor.storage,
                                               shift: shift,
                                               mode: .sameSizeResult)

    /// Holds the (continuously updated) remaining part of the dividend,
    /// which eventually becomes the remainder.
    var remainder = Self.specialLeftShift(value: dividend.storage,
                                          shift: shift,
                                          mode: .alwaysAddOneDigit)

    // Preparations before loop:

    // We no longer need 'dividend' since we will be using 'remainder',
    // for actual division. We will use it to accumulate result instead.
    dividend.storage.transformEveryWord { _ in 0 }
    // In each iteration we will be divising 'remainderHighWords' by 'divisorHighWords'
    // to estimate quotient word.
    let divisorHighWords = (shiftedDivisor[n - 1], shiftedDivisor[n - 2])
    // This will hold 'divisor * quotientGuess',
    // so that we do not have to allocate on every iteration.
    var mulBuffer = BigIntStorage(minimumCapacity: n + 1)

    // D2.
    // Iterate over the dividend's digit (like the 'grad school' algorithm).
    for j in stride(from: m, through: 0, by: -1) {
      // D3.
      // Estimate the current quotient digit by dividing the most significant
      // digits of dividend and divisor.
      // The result may be exact or it may be '1' too high.
      let remainderHighWords = (remainder[j + n], remainder[j + n - 1], remainder[j + n - 2])
      var quotientGuess = Self.approximateQuotient(dividing: remainderHighWords,
                                                   by: divisorHighWords)

      // D4.
      // Multiply the divisor with the current quotient digit,
      // and subtract it from the dividend.
      // If there was 'borrow', then the quotient digit was '1' too high,
      // so we must correct it and undo one subtraction of the (shifted) divisor.
      Self.internalMultiply(lhs: shiftedDivisor, rhs: quotientGuess, into: &mulBuffer)
      let borrow = Self.inplaceSub(lhs: &remainder, rhs: mulBuffer, startIndex: j)
      if borrow != 0 {
        let carry = Self.inplaceAdd(lhs: &remainder, rhs: shiftedDivisor, startIndex: j)
        remainder[j + n] += carry
        quotientGuess -= 1
      }

      dividend.storage[j] = quotientGuess
    }

    // 'dividend' holds the result
    dividend.fixInvariants()

    // Undo the 'specialLeftShift' from the start of this function
    Self.specialRightShift(value: &remainder, shift: shift)
    remainder.fixInvariants()
    return BigIntHeap(storage: remainder)
  }

  // MARK: - Heap - Approximate quotient

  private static func approximateQuotient(
    dividing x: (Word, Word, Word), // swiftlint:disable:this large_tuple
    by y: (Word, Word)
  ) -> Word {
    // 601 / 61 = 10 = Word.max (Word = decimal in this case)
    if x.0 == y.0 {
      return Word.max
    }

    // Divide 2 highest digits of 'x' by highest digit of 'y'
    var (high, low) = y.0.dividingFullWidth((x.0, x.1))

    // Decrement the quotient estimate as needed by looking at the next
    // digit, i.e. by testing whether
    // high * y.1 > (low << Word.bitWidth) + x.2
    while Self.productGreaterThan(factor1: high, factor2: y.1, high: low, low: x.2) {
      high -= 1
      let oldLow = low
      low += y.0

      // v[n-1] >= 0, so this tests for overflow.
      if low < oldLow {
        break
      }
    }

    return high
  }

  /// Returns whether `(factor1 * factor2) > (high << kDigitBits) + low`.
  private static func productGreaterThan(factor1: Word,
                                         factor2: Word,
                                         high: Word,
                                         low: Word) -> Bool {
    let (resultHigh, resultLow) = factor1.multipliedFullWidth(by: factor2)
    return resultHigh > high || (resultHigh == high && resultLow > low)
  }

  // MARK: - Heap - Special shifts

  private enum SpecialLeftShiftMode {
    case sameSizeResult
    case alwaysAddOneDigit
  }

  private static func specialLeftShift(value: BigIntStorage,
                                       shift: Int,
                                       mode: SpecialLeftShiftMode) -> BigIntStorage {
    var result: BigIntStorage
    switch mode {
    case .sameSizeResult:
      result = BigIntStorage(repeating: .zero, count: value.count)
    case .alwaysAddOneDigit:
      result = BigIntStorage(repeating: .zero, count: value.count + 1)
      result[result.count - 1] = result[value.count - 1] >> (Word.bitWidth - shift)
    }

    for i in stride(from: value.count - 1, to: 0, by: -1) {
      let high = value[i] << shift
      let low = value[i - 1] >> (Word.bitWidth - shift)
      result[i] = high | low
    }

    result[0] = value[0] << shift
    return result
  }

  private static func specialRightShift(value: inout BigIntStorage, shift: Int) {
    if shift == 0 {
      return
    }

    for i in 0..<(value.count - 1) {
      let low = value[i] >> shift
      let high = value[i + 1] << (Word.bitWidth - shift)
      value[i] = high | low
    }

    value[value.count - 1] = value[value.count - 1] >> shift
  }

  // MARK: - Heap - Add, sub and mul

  /// Adds `summand` onto `value`, starting with `summand's` 0th digit
  /// at `value's` `startIndex'th` digit.
  ///
  /// Returns the `carry` (0 or 1).
  private static func inplaceAdd(lhs: inout BigIntStorage,
                                 rhs: BigIntStorage,
                                 startIndex: Int) -> Word {
    var carry: Word = 0
    for i in 0..<lhs.count {
      let (word1, overflow1) = lhs[startIndex + i].addingReportingOverflow(rhs[i])
      let (word2, overflow2) = word1.addingReportingOverflow(carry)

      lhs[startIndex + i] = word2
      carry = (overflow1 ? 1 : 0) + (overflow2 ? 1 : 0)
    }

    return carry
  }

  /// Subtracts `subtrahend` from `value`, starting with `subtrahend's` 0th digit
  /// and `value's` `startIndex-th` digit.
  ///
  /// Returns the `borrow` (0 or 1).
  private static func inplaceSub(lhs: inout BigIntStorage,
                                 rhs: BigIntStorage,
                                 startIndex: Int) -> Word {
    // TODO: In 'sub' rename 'carry' to borrow
    var borrow: Word = 0
    for i in 0..<lhs.count {
      let (word1, borrow1) = lhs[startIndex + i].subtractingReportingOverflow(rhs[i])
      let (word2, borrow2) = word1.subtractingReportingOverflow(borrow)

      lhs[startIndex + i] = word2
      borrow = (borrow1 ? 1 : 0) + (borrow2 ? 1 : 0)
    }

    return borrow
  }

  /// Multiplies `source` with `factor` and adds `summand` to the result.
  /// `result` and `source` may be the same BigInt for inplace modification.
  private static func internalMultiply(lhs: BigIntStorage,
                                       rhs: Word,
                                       into result: inout BigIntStorage) {
    result.removeAll()

    var carry: Word = 0
    for i in 0..<lhs.count {
      let (high, low) = lhs[i].multipliedFullWidth(by: rhs)
      let (word, overflow) = low.addingReportingOverflow(carry)
      result.append(word)

      carry = high &+ (overflow ? 1 : 0)
    }

    // Add the leftover carry
    if carry != 0 {
      result.append(carry)
    }
  }

  // TODO: Mod
  // TODO: Div mod
}
