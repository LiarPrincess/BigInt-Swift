// A lot of this code was taken from:
// https://github.com/apple/swift/blob/master/test/Prototypes/BigInt.swift

// swiftlint:disable file_length

// TODO: Make it struct and store pointer to buffer, value at 0 will be count
internal class BigIntHeap: Comparable, CustomStringConvertible, CustomDebugStringConvertible {

  internal typealias Word = UInt64

  // MARK: - Properties

  /// The binary representation of the value's magnitude,
  /// with the least significant word at index `0`.
  ///
  /// - `data` has no trailing zero elements
  /// - If `self == 0`, then `isNegative == false` and `data == []`
  internal private(set) var data: [Word]

  /// A Boolean value indicating whether this instance is negative.
  internal private(set) var isNegative: Bool

  /// `0` is also positive.
  internal var isPositive: Bool {
    get { return !self.isNegative }
    set { self.isNegative = !newValue }
  }

  internal var isZero: Bool {
    return self.data.isEmpty
  }

  private var count: Int {
    return self.data.count
  }

  internal var bitWidth: Int {
    // Check for 0
    guard let last = self.data.last else {
      return Word.zero.bitWidth
    }

    let sign = 1
    return self.count * Word.bitWidth - last.leadingZeroBitCount + sign
  }

  internal var leadingZeroBitCount: Int {
    // Check for 0
    guard let last = self.data.last else {
      return Word.zero.leadingZeroBitCount
    }

    return last.leadingZeroBitCount
  }

  internal var trailingZeroBitCount: Int {
    for (index, word) in self.data.enumerated() {
      if !word.isZero {
        return index * word.bitWidth + word.trailingZeroBitCount
      }
    }

    assert(self.isZero)
    return Word.zero.trailingZeroBitCount
  }

  internal var minRequiredWidth: Int {
    // Check for 0
    guard let last = self.data.last else {
      return Word.zero.minRequiredWidth
    }

    let widthWithoutLast = (self.count - 1) * Word.bitWidth
    return widthWithoutLast + last.minRequiredWidth
  }

  private var hasMagnitudeOfOne: Bool {
    guard self.count == 1 else {
      return false
    }

    return self.data[0] == 1
  }

  // MARK: - Init

  internal init(isNegative: Bool, word: Word) {
    // Zero is always positive
    self.isNegative = word.isZero ? false : isNegative
    self.data = [word]
    self.checkInvariants()
  }

  internal init(isNegative: Bool, data: [Word]) {
    var dataCopy = data
    Self.trimPrefixZeros(data: &dataCopy)

    // Zero is always positive
    self.isNegative = dataCopy.isEmpty ? false : isNegative
    self.data = dataCopy

    self.checkInvariants()
  }

  internal init<T: BinaryInteger>(_ value: T) {
    self.isNegative = value.isNegative
    let magnitude = value.magnitude

    // We are assuming that there is no bigger unsigned 'int' than 'UInt64'.
    // Otherwise we would have to loop through 'value.words'
    guard let word = Word(exactly: magnitude) else {
      trap("\(T.self) is not (yet) supported in 'BigInt.init'")
    }

    self.data = [word]
    self.checkInvariants()
  }

  // MARK: - Unary operations

  internal func negate() {
    defer { self.checkInvariants() }

    if self.isZero {
      return
    }

    self.isNegative.toggle()
    self.fixInvariants()
  }

  internal func invert() {
    defer { self.checkInvariants() }

    // ~x = -x - 1
    self.negate()
    self.sub(other: 1)
    self.fixInvariants()
  }

  // MARK: - Add

  internal func add<T: FixedWidthInteger>(other: T) {
    defer { self.checkInvariants() }

    if other.isZero {
      return
    }

    if self.isZero {
      let word = Word(other.magnitude)
      self.data = [word]
      self.isNegative = other.isNegative
      return
    }

    if self.isNegative == other.isNegative {
      Self.addMagnitude(lhs: &self.data, rhs: other)
      return
    }

    // Self positive, other negative: x + (-y) = x - y
    if self.isPositive {
      assert(other.isNegative)
      let otherPositive = other.magnitude // Just using '-' may overflow!
      self.sub(other: otherPositive)
      return
    }

    // Self negative, other positive:  -x + y = -(x - y)
    assert(self.isNegative && other.isPositive)
    self.negate()
    self.sub(other: other)
    self.negate()
    self.fixInvariants()
  }

  private static func addMagnitude<T: FixedWidthInteger>(lhs: inout [Word], rhs: T) {
    if rhs.isZero {
      return
    }

    let rhsWord = Word(rhs.magnitude)

    if lhs.isEmpty {
      lhs.append(rhsWord)
      return
    }

    var carry: Word
    (carry, lhs[0]) = lhs[0].addingFullWidth(rhsWord)

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

  internal func add(other: BigIntHeap) {
    defer { self.checkInvariants() }

    if other.isZero {
      return
    }

    if self.isZero {
      self.isNegative = other.isNegative
      self.data = other.data
      return
    }

    // Same sign
    if self.isNegative == other.isNegative {
      Self.addMagnitudes(lhs: &self.data, rhs: other.data)
      return
    }

    // Self positive, other negative: x + (-y) = x - y
    if self.isPositive {
      assert(other.isNegative)
      let otherPositive = other.copy()
      otherPositive.negate()
      self.sub(other: otherPositive)
      return
    }

    // Self negative, other positive:  -x + y = -(x - y)
    assert(self.isNegative && other.isPositive)
    self.negate()
    self.sub(other: other)
    self.negate()
    self.fixInvariants()
  }

  /// Both are positive or both are negative.
  ///
  /// Basically a copy of Swift '_unsignedAdd' function
  /// (see top of this file for link).
  private static func addMagnitudes(lhs: inout [Word], rhs: [Word]) {
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
        // No more action needed if there's nothing to carry
        if carry == 0 { break }
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

  // MARK: - Sub

  internal func sub<T: FixedWidthInteger>(other: T) {
    defer { self.checkInvariants() }

    if other.isZero {
      return
    }

    if self.isZero {
      let word = Word(other.magnitude)
      self.data = [word]
      self.isNegative = !other.isNegative
      return
    }

    // We can simply add magnitudes when:
    // - self.isNegative && other.isPositive (for example: -5 - 6 = -11)
    // - self.isPositive && other.isNegative (for example:  5 - (-6) = 5 + 6 = 11)
    // which is the same as:
    if self.isNegative != other.isNegative {
      Self.addMagnitude(lhs: &self.data, rhs: other)
      return
    }

    // Both have the same sign, for example '1 - 1' or '-2 - (-3)'.
    // That means that we may need to cross 0.
    switch Self.compareMagnitudes(lhs: self.data, rhs: other) {
    case .equal: // 1 - 1
      self.setToZero()
    case .less: // 1 - 2
      // Biggest Swift 'BinaryInteger' type is [U]Int64.
      // Its magnitude is in range of our 'Word', so we can simply:
      let otherMagnitude = Word(other.magnitude)

      assert(self.data[0] < otherMagnitude)
      let result = otherMagnitude - self.data[0]

      self.data = [result]
      self.isNegative.toggle() // We crossed 0

    case .greater: // 2 - 1
      Self.subMagnitude(bigger: &self.data, smaller: other)
    }
  }

  private static func subMagnitude<T: FixedWidthInteger>(bigger: inout [Word],
                                                         smaller: T) {
    if smaller.isZero {
      return
    }

    let smallerWord = Word(smaller.magnitude)

    if bigger.isEmpty {
      bigger.append(smallerWord)
      return
    }

    var carry: Word
    (carry, bigger[0]) = bigger[0].subtractingFullWidth(smallerWord)

    for i in 1..<bigger.count {
      // No more action needed if there's nothing to carry
      if carry == 0 { break }
      (carry, bigger[i]) = bigger[i].subtractingFullWidth(carry)
    }

    assert(carry == 0)
  }

  internal func sub(other: BigIntHeap) {
    defer { self.checkInvariants() }

    if other.isZero {
      return
    }

    if self.isZero {
      let otherCopy = other.copy()
      otherCopy.negate()
      self.data = otherCopy.data
      self.isNegative = otherCopy.isNegative
      return
    }

    // We can simply add magnitudes when:
    // - self.isNegative && other.isPositive (for example: -5 - 6 = -11)
    // - self.isPositive && other.isNegative (for example:  5 - (-6) = 5 + 6 = 11)
    // which is the same as:
    if self.isNegative != other.isNegative {
      Self.addMagnitudes(lhs: &self.data, rhs: other.data)
      return
    }

    // Both have the same sign, for example '1 - 1' or '-2 - (-3)'.
    // That means that we may need to cross 0.
    switch Self.compareMagnitudes(lhs: self.data, rhs: other.data) {
    case .equal: // 1 - 1
      self.setToZero()
    case .less: // 1 - 2
      // smaller - greater = -greater + smaller = -(greater - smaller)
      var otherCopy = other.data
      Self.subMagnitudes(bigger: &otherCopy, smaller: self.data)
      self.data = otherCopy
      self.isNegative.toggle() // We crossed 0
      self.fixInvariants() // Fix possible '0' prefix
    case .greater: // 2 - 1
      Self.subMagnitudes(bigger: &self.data, smaller: other.data)
      self.fixInvariants() // Fix possible '0' prefix
    }
  }

  /// Basically a copy of Swift '_unsignedSubtract' function
  /// (see top of this file for link).
  private static func subMagnitudes(bigger: inout [Word],
                                    smaller: [Word]) {
    var carry: Word = 0
    for i in 0..<smaller.count {
      (carry, bigger[i]) = bigger[i].subtractingFullWidth(smaller[i], carry)
    }

    for i in smaller.count..<bigger.count {
      // No more action needed if there's nothing to carry
      if carry == 0 { break }
      (carry, bigger[i]) = bigger[i].subtractingFullWidth(carry)
    }

    assert(carry == 0)
  }

  // MARK: - Mul

  internal func mul<T: FixedWidthInteger>(other: T) {
    defer { self.checkInvariants() }

    // Special case: 0
    if other.isZero {
      self.setToZero()
      return
    }

    if self.isZero {
      return
    }

    // Special case: 1
    if other == T(1) {
      return
    }

    let hasMagnitudeOfOne = self.hasMagnitudeOfOne
    if self.isPositive && hasMagnitudeOfOne {
      let word = Word(other.magnitude)
      self.data = [word]
      self.isNegative = other.isNegative
      return
    }

    // Special case: -1
    if T.isSigned && other == T(-1) {
      self.negate()
      return
    }

    if self.isNegative && hasMagnitudeOfOne {
      let word = Word(other.magnitude)
      self.data = [word]
      self.isNegative = !other.isNegative // switch sign
      return
    }

    // But wait, there is more:
    // if 'other' is a power of 2 -> we can just shift left
    let otherLSB = other.trailingZeroBitCount
    let isOtherPowerOf2 = other >> otherLSB == 1
    if isOtherPowerOf2 {
      self.shiftLeft(count: otherLSB)
      return
    }

    // Non-special case:
    // If the signs are the same then we are positive.
    // '1 * 2 = 2' and also (-1) * (-2) = 2
    Self.mulMagnitude(lhs: &self.data, rhs: other)
    self.isNegative = self.isNegative != other.isNegative
  }

  private static func mulMagnitude<T: FixedWidthInteger>(lhs: inout [Word],
                                                         rhs: T) {
    if rhs.isZero {
      lhs = []
      return
    }

    if lhs.isEmpty {
      return
    }

    var carry: Word = 0
    let rhsWord = Word(rhs.magnitude)

    for i in 0..<lhs.count {
      let (low, high) = lhs[i].multipliedFullWidth(by: rhsWord)
      (carry, lhs[i]) = low.addingFullWidth(carry)
      carry = carry &+ high
    }

    // Add the leftover carry
    if carry != 0 {
      lhs.append(carry)
    }
  }

  /// Basically a copy of Swift '*=' operator
  /// (see top of this file for link).
  internal func mul(other: BigIntHeap) {
    defer { self.checkInvariants() }

    // Special case: 0
    if other.isZero {
      self.setToZero()
      return
    }

    if self.isZero {
      return
    }

    // Special case: 1
    if other.isPositive && other.hasMagnitudeOfOne {
      return
    }

    if self.isPositive && self.hasMagnitudeOfOne {
      self.data = other.data
      self.isNegative = other.isNegative
      return
    }

    // Special case: -1
    if other.isNegative && other.hasMagnitudeOfOne {
      self.negate()
      return
    }

    if self.isNegative && self.hasMagnitudeOfOne {
      self.data = other.data
      self.isNegative = !other.isNegative // switch sign
      return
    }

    // Non-special case:
    // If the signs are the same then we are positive.
    // '1 * 2 = 2' and also (-1) * (-2) = 2
    self.data = Self.mulMagnitudes(lhs: self.data, rhs: other.data)
    self.isNegative = self.isNegative != other.isNegative
    self.fixInvariants()
  }

  /// Basically a copy of Swift '*=' operator
  /// (see top of this file for link).
  private static func mulMagnitudes(lhs: [Word], rhs: [Word]) -> [Word] {
    var result = Array(repeating: Word.zero, count: lhs.count + rhs.count)
    let (a, b) = lhs.count > rhs.count ? (lhs, rhs) : (rhs, lhs)
    assert(a.count >= b.count)

    var carry = Word.zero
    for ai in 0..<a.count {
      carry = 0
      for bi in 0..<b.count {
        // Each iteration needs to perform this operation:
        //
        //     result[ai + bi] += (a[ai] * b[bi]) + carry
        //
        // However, `a[ai] * b[bi]` produces a double-width result, and both
        // additions can overflow to a higher word. The following two lines
        // capture the low word of the multiplication and additions in
        // `result[ai + bi]` and any addition overflow in `carry`.
        let (high, low) = a[ai].multipliedFullWidth(by: b[bi])
        (carry, result[ai + bi]) = result[ai + bi].addingFullWidth(low, carry)

        // Now we combine the high word of the multiplication with any addition
        // overflow. It is safe to add `product.high` and `carry` here without
        // checking for overflow, because if `product.high == .max - 1`, then
        // `carry <= 1`. Otherwise, `carry <= 2`.
        //
        // Worst-case (aka 9 + 9*9 + 9):
        //
        //       result         a[ai]        b[bi]         carry
        //      0b11111111 + (0b11111111 * 0b11111111) + 0b11111111
        //      0b11111111 + (0b11111110_____00000001) + 0b11111111
        //                   (0b11111111_____00000000) + 0b11111111
        //                   (0b11111111_____11111111)
        //
        // Second-worse case:
        //
        //      0b11111111 + (0b11111111 * 0b11111110) + 0b11111111
        //      0b11111111 + (0b11111101_____00000010) + 0b11111111
        //                   (0b11111110_____00000001) + 0b11111111
        //                   (0b11111111_____00000000)
        assert(!high.addingReportingOverflow(carry).overflow)
        carry = high &+ carry
      }

      // Leftover `carry` is inserted in new highest word.
      assert(result[ai + b.count] == 0)
      result[ai + b.count] = carry
    }

    return result
  }

  // MARK: - Div

  internal struct IntRemainder {

    internal let isNegative: Bool
    internal let value: Word

    fileprivate init(isNegative: Bool, value: Word) {
      self.isNegative = value.isZero ? false : isNegative
      self.value = value
    }

    fileprivate static var zero: IntRemainder {
      return IntRemainder(isNegative: false, value: .zero)
    }
  }

  /// Returns remainder.
  ///
  /// Sign:
  /// - sign of the result follows standard marh rules:
  ///   if the operands had the same sign then positive, otherwise negative
  /// - sign of the remainder is the same `self` sign
  ///
  /// Based on following Swift code:
  /// ```
  /// let x = 10
  /// let y = 3
  ///
  /// print(" \(x) /  \(y) =", x / y, "rem:", x % y)
  /// print(" \(x) / -\(y) =", x / (-y), "rem:", x % (-y))
  /// print("-\(x) /  \(y) =", (-x) / y, "rem:", (-x) % y)
  /// print("-\(x) / -\(y) =", (-x) / (-y), "rem:", (-x) % (-y))
  /// ```
  ///
  /// - Important:
  /// In Python sign acts a bit differently
  internal func divMod<T: FixedWidthInteger>(other: T) -> IntRemainder {
    defer { self.checkInvariants() }

    precondition(!other.isZero, "Division by zero")

    if self.isZero {
      // 0 divided by anything is 0
      return .zero
    }

    if other == T(1) {
      return .zero // x / 1 = x
    }

    if T.isSigned && other == T(-1) {
      self.negate() // x / (-1) = -x
      return .zero
    }

    // Remainder will have the same sign as we (now).
    let remainderIsNegative = self.isNegative
    // If the signs are the same then we are positive.
    // '2 / 1 = 2' and also (-2) * (-1) = 2
    self.isNegative = self.isNegative != other.isNegative

    // From now on, any operations must not take into account sign,
    // as it was already set to its final value!

    switch BigIntHeap.compareMagnitudes(lhs: self.data, rhs: other) {
    case .equal: // 5 / 5 = 1 rem 0 and also 5 / (-5) = -1 rem 0
      self.setToOne()
      return .zero

    case .less: // 3 / 5 = 0 rem 3
      // We have exactly 1 word (we checked for 0 and we are less than single int)
      let remainder = self.data[0]
      self.setToZero()
      return IntRemainder(isNegative: remainderIsNegative, value: remainder)

    case .greater:
      let remainder = Self.divModMagnitude(lhs: &self.data, rhs: other)
      self.fixInvariants()
      return IntRemainder(isNegative: remainderIsNegative, value: remainder)
    }
  }

  /// Returns remainder.
  private static func divModMagnitude<T: FixedWidthInteger>(
    lhs: inout [Word],
    rhs: T
  ) -> Word {
    // If 'rhs' is a power of 2 -> we can just shift right
    let otherLSB = rhs.trailingZeroBitCount
    let isOtherPowerOf2 = rhs >> otherLSB == 1
    if isOtherPowerOf2 {
      // Remainder - part we are 'chopping' off
      // (just like in Overcooked: chop, chop, chop)
      let remainderMask = ~(~Word.zero << otherLSB)
      let remainder = lhs[0] & remainderMask
//      self.shiftRight(count: otherLSB) // TODO: Shift for magnitude
      return remainder
    }

    let rhsWord = Word(rhs.magnitude)

    var carry = Word.zero
    for i in (0..<lhs.count).reversed() {
      let x = (high: carry, low: lhs[i])
      (lhs[i], carry) = rhsWord.dividingFullWidth(x)
    }

    return carry
  }

  internal struct BigIntRemainder {

    internal let isNegative: Bool
    internal let data: [Word]

    fileprivate init(isNegative: Bool, data: [Word]) {
      self.isNegative = data.isEmpty ? false : isNegative
      self.data = data
    }

    fileprivate static var zero: BigIntRemainder {
      return BigIntRemainder(isNegative: false, data: [])
    }
  }

  /// Basically a copy of Swift '_internalDivide' operator
  /// (see top of this file for link).
  internal func divMod(other: BigIntHeap) -> BigIntRemainder {
    defer { self.checkInvariants() }

    // Special cases: 'other' is 0, 1 or -1
    precondition(!other.isZero, "Division by zero")

    if self.isZero {
      // 0 divided by anything is 0
      return .zero
    }

    if other.isPositive && other.hasMagnitudeOfOne {
      return .zero // x / 1 = x
    }

    if other.isNegative && other.hasMagnitudeOfOne {
      self.negate() // x / (-1) = -x
      return .zero
    }

    // TODO: Special case when 'other.count = 1'

    // Remainder will have the same sign as we (now).
    let remainderIsNegative = self.isNegative
    // If the signs are the same then we are positive.
    // '2 / 1 = 2' and also (-2) * (-1) = 2
    self.isNegative = self.isNegative != other.isNegative

    // From now on, any operations must not take into account sign,
    // as it was already set to its final value!

    switch BigIntHeap.compareMagnitudes(lhs: self.data, rhs: other.data) {
    case .equal: // 5 / 5 = 1 rem 0 and also 5 / (-5) = -1 rem 0
      self.setToOne()
      return .zero

    case .less: // 3 / 5 = 0 rem 3
      // Bascially return 'self' as remainder
      let remainder = self.data
      self.setToZero()
      return BigIntRemainder(isNegative: remainderIsNegative, data: remainder)

    case .greater:
      // Oh no! We have to implement proper div logic!
//      let remainder = Self.divModMagnitudes(lhs: &self.data, rhs: other.data)
//      self.fixInvariants()
//      return BigIntRemainder(isNegative: remainderIsNegative, data: remainder)
      fatalError()
    }
  }
/*
  /// Returns remainder.
  ///
  /// Basically a copy of Swift '_internalDivide' operator
  /// (see top of this file for link).
  private static func divModMagnitudes(lhs: inout [Word],
                                       rhs: [Word]) -> [Word] {
    precondition(!rhs.isEmpty, "Division by zero")

    if lhs.isEmpty {
      // 0 divided by anything is 0
      return []
    }

    // At this point both are non-empty
    let n = (lhs.count - rhs.count) * Word.bitWidth

    var remainder = lhs
    var quotient = 0

    var tempRHS = rhs << n
    var tempQuotient = 1 << n

    for _ in (0...n) {
      switch BigIntHeap.compareMagnitudes(lhs: remainder, rhs: tempRHS) {
      case .greater:
        remainder -= tempRHS
        quotient += tempQuotient
      case .equal,
           .less:
        break
      }

//      tempRHS >>= 1
//      tempQuotient >>= 1
    }

    fatalError()
  }
*/
  // MARK: - Shift

  internal func shiftLeft<T: FixedWidthInteger>(count: T) { }
  internal func shiftRight<T: FixedWidthInteger>(count: T) { }

  // MARK: - String

  internal var description: String {
    return self.toString(radix: 10, uppercase: false)
  }

  internal var debugDescription: String {
    let value = self.toString(radix: 10, uppercase: false)
    return "BigIntHeap(\(value))"
  }

  internal func toString(radix: Int, uppercase: Bool) -> String {
    switch self.data.count {
    case 0:
      return "0"
    case 1:
      let value = self.data[0]
      let sign = self.isNegative ? "-" : ""
      return sign + String(value, radix: radix, uppercase: uppercase)
    default:
      // TODO: 'toString' for big ints
      fatalError("Not implemented")
    }
  }

  // MARK: - Equatable

  internal static func == (heap: BigIntHeap, smi: Smi) -> Bool {
    // Different signs are never equal
    guard heap.isNegative == smi.isNegative else {
      return false
    }

    switch Self.compareMagnitudes(lhs: heap.data, rhs: smi.value) {
    case .equal:
      return true
    case .less,
         .greater:
      return false
    }
  }

  internal static func == (lhs: BigIntHeap, rhs: BigIntHeap) -> Bool {
    return lhs.isNegative == rhs.isNegative && lhs.data == rhs.data
  }

  // MARK: - Comparable

  internal static func >= (heap: BigIntHeap, smi: Smi) -> Bool {
    // Negative values are always smaller than positive ones (because math...)
    guard heap.isNegative == smi.isNegative else {
      return smi.isNegative
    }

    switch Self.compareMagnitudes(lhs: heap.data, rhs: smi.value) {
    case .equal,
         .greater:
      return true
    case .less:
      return false
    }
  }

  internal static func < (heap: BigIntHeap, smi: Smi) -> Bool {
    // Negative values are always smaller than positive ones (because math...)
    guard heap.isNegative == smi.isNegative else {
      return heap.isNegative
    }

    switch Self.compareMagnitudes(lhs: heap.data, rhs: smi.value) {
    case .less:
      return true
    case .equal,
         .greater:
      return false
    }
  }

  internal static func < (lhs: BigIntHeap, rhs: BigIntHeap) -> Bool {
    // Negative values are always smaller than positive ones (because math...)
    guard lhs.isNegative == rhs.isNegative else {
      return lhs.isNegative
    }

    switch Self.compareMagnitudes(lhs: lhs.data, rhs: rhs.data) {
    case .less:
      return true
    case .equal,
         .greater:
      return false
    }
  }

  private enum CompareMagnitudes {
    case equal
    case less
    case greater
  }

  private static func compareMagnitudes<T: BinaryInteger>(
    lhs: [Word],
    rhs: T
  ) -> CompareMagnitudes {
    // If we have more words than 1 then we are our of range of smi
    if lhs.count > 1 {
      return .greater
    }

    // We have only 1 word in heap -> compare with value
    let lhsWord = lhs[0]
    let rhsWord = Word(rhs.magnitude)
    return lhsWord == rhsWord ? .equal :
           lhsWord > rhsWord ? .greater :
          .less
  }

  private static func compareMagnitudes(lhs: [Word],
                                        rhs: [Word]) -> CompareMagnitudes {
    // Shorter number is always smaller
    guard lhs.count == rhs.count else {
      return lhs.count < rhs.count ? .less : .greater
    }

    // Compare from most significant word
    let indices = stride(from: lhs.count, through: 0, by: -1)
    for index in indices {
      let lhsWord = lhs[index]
      let rhsWord = rhs[index]

      if lhsWord < rhsWord {
        return .less
      }

      if lhsWord > rhsWord {
        return .greater
      }

      // Equal -> compare next word
    }

    return .equal
  }

  // MARK: - Factory

  private func setToZero() {
    self.isNegative = false
    self.data = []
  }

  private func setToOne() {
    self.isNegative = false
    self.data = [Word(1)]
  }

  // MARK: - Invariants

  private func fixInvariants() {
    Self.trimPrefixZeros(data: &self.data)

    // Zero is always positive
    if self.data.isEmpty {
      self.isNegative = false
    }
  }

  private static func trimPrefixZeros(data: inout [Word]) {
    while let last = data.last, last.isZero {
      data.removeLast()
    }
  }

  private func checkInvariants(source: StaticString = #function) {
    if let last = self.data.last {
      assert(last != 0, "\(source): zero prefix in BigInt")
    } else {
      // 'self.data' is empty
      assert(self.isNegative == false, "\(source): isNegative with empty data")
    }
  }

  // MARK: - Copy

  internal func copy() -> BigIntHeap {
    return BigIntHeap(isNegative: self.isNegative, data: self.data)
  }

  // MARK: - Type conversion

  internal var asNormalizedBigInt: BigInt {
    if let smi = self.asSmi {
      return BigInt(smi)
    }

    return BigInt(self)
  }

  private var asSmi: Smi? {
    guard self.count == 1 else {
      return nil
    }

    let maxSmiSigned = self.isNegative ? Smi.Storage.min : Smi.Storage.max
    let maxSmiUnsigned = maxSmiSigned.magnitude

    let unsignedValue = self.data[0]
    guard unsignedValue <= maxSmiUnsigned else {
      return nil
    }

    // Ok, we are in range
    // We cannot do calculations in 'Smi.Storage',
    // because if are were 'min' then we would overfow
    let sign = self.isNegative ? -1 : 1
    let value = sign * Int(unsignedValue)
    return Smi(Smi.Storage(value))
  }
}
