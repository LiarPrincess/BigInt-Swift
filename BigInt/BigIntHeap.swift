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

  internal var minRequiredWidth: Int {
    guard let last = self.data.last else {
      return (0).minRequiredWidth
    }

    let widthWithoutLast = (self.count - 1) * Word.bitWidth
    return widthWithoutLast + last.minRequiredWidth
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

  internal func add<T: BinaryInteger>(other: T) {
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

  private static func addMagnitude<T: BinaryInteger>(lhs: inout [Word], rhs: T) {
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

  internal func sub<T: BinaryInteger>(other: T) {
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
    switch Self.compareMagnitudes(lhs: self, rhs: other) {
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

  private static func subMagnitude<T: BinaryInteger>(bigger: inout [Word],
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
    switch Self.compareMagnitudes(lhs: self, rhs: other) {
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

  private var hasMagnitudeOfOne: Bool {
    guard self.count == 1 else {
      return false
    }

    return self.data[0] == 1
  }

  internal func mul<T: BinaryInteger>(other: T) {
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

    // Special case: 'other' is a power of 2 -> we can just shift left
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

  private static func mulMagnitude<T: BinaryInteger>(lhs: inout [Word],
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
    let otherHasMagnitudeOfOne = other.hasMagnitudeOfOne
    if other.isPositive && otherHasMagnitudeOfOne {
      return
    }

    let selfHasMagnitudeOfOne = self.hasMagnitudeOfOne
    if self.isPositive && selfHasMagnitudeOfOne {
      self.data = other.data
      self.isNegative = other.isNegative
      return
    }

    // Special case: -1
    if other.isNegative && otherHasMagnitudeOfOne {
      self.negate()
      return
    }

    if self.isNegative && selfHasMagnitudeOfOne {
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

  // MARK: - Shift

  internal func shiftLeft<T: BinaryInteger>(count: T) { }

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

    switch Self.compareMagnitudes(lhs: heap, rhs: smi.value) {
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

    switch Self.compareMagnitudes(lhs: heap, rhs: smi.value) {
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

    switch Self.compareMagnitudes(lhs: heap, rhs: smi.value) {
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

    switch Self.compareMagnitudes(lhs: lhs, rhs: rhs) {
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
    lhs: BigIntHeap,
    rhs: T
  ) -> CompareMagnitudes {
    // If we have more words than 1 then we are our of range of smi
    if lhs.count > 1 {
      return .greater
    }

    // We have only 1 word in heap -> compare with value
    let lhsWord = lhs.data[0]
    let rhsWord = Word(rhs.magnitude)
    return lhsWord == rhsWord ? .equal :
           lhsWord > rhsWord ? .greater :
          .less
  }

  private static func compareMagnitudes(lhs: BigIntHeap,
                                        rhs: BigIntHeap) -> CompareMagnitudes {
    // Shorter number is always smaller
    guard lhs.count == rhs.count else {
      return lhs.count < rhs.count ? .less : .greater
    }

    // Compare from most significant word
    let indices = stride(from: lhs.data.count, through: 0, by: -1)
    for index in indices {
      let lhsWord = lhs.data[index]
      let rhsWord = rhs.data[index]

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
