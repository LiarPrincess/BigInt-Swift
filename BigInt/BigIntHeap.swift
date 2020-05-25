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

  internal var isPositive: Bool {
    return !self.isNegative
  }

  internal var isZero: Bool {
    return self.data.isEmpty
  }

  private var count: Int {
    return self.data.count
  }

  // TODO: minRequiredWidth

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
      self.isNegative = other.isNegative
      self.data = [word]
      return
    }

    if self.isNegative == other.isNegative {
      self.addSameSign(other: other)
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

  /// Both are positive or both are negative.
  private func addSameSign<T: BinaryInteger>(other _other: T) {
    // swiftlint:disable:next empty_count
    assert(self.data.count != 0, "0 should be handled earlier")

    var carry: Word
    let other = Word(_other.magnitude)
    (carry, self.data[0]) = Self.add(self.data[0], other)

    for i in 1..<data.count {
      guard carry > 0 else {
        break
      }

      (carry, self.data[i]) = Self.add(self.data[i], other)
    }

    if carry > 0 {
      self.data.append(1)
    }

    // No need to fix invariants
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
      (carry, lhs[i]) = Self.add(lhs[i], rhs[i], carry)
    }

    // If there are leftover words in 'lhs', just need to handle any carries
    if lhs.count > rhs.count {
      for i in commonCount..<maxCount {
        // No more action needed if there's nothing to carry
        if carry == 0 { break }
        (carry, lhs[i]) = Self.add(lhs[i], carry)
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
        (carry, word) = Self.add(rhs[i], carry)
        lhs.append(word)
      }
    }

    // If there's any carry left, add it now
    if carry != 0 {
      lhs.append(1)
    }
  }

  private typealias PartialAddResult = (carry: Word, result: Word)

  private static func add(_ x: Word, _ y: Word) -> PartialAddResult {
    let (result, overflow) = x.addingReportingOverflow(y)
    let carry: Word = overflow ? 1 : 0
    return (carry, result)
  }

  private static func add(_ x: Word, _ y: Word, _ z: Word) -> PartialAddResult {
    let (xy, overflow1) = x.addingReportingOverflow(y)
    let (xyz, overflow2) = xy.addingReportingOverflow(z)
    let carry: Word = (overflow1 ? 1 : 0) + (overflow2 ? 1 : 0)
    return (carry, xyz)
  }

  // MARK: - Sub

  internal func sub<T: BinaryInteger>(other: T) {
    fatalError()
  }

  internal func sub(other: BigIntHeap) {
    defer { self.checkInvariants() }

    if other.isZero {
      return
    }

    if self.isZero {
      let otherCopy = other.copy()
      otherCopy.negate()
      self.isNegative = otherCopy.isNegative
      self.data = otherCopy.data
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
      (carry, bigger[i]) = Self.sub(bigger[i], smaller[i], carry)
    }

    for i in smaller.count..<bigger.count {
      // No more action needed if there's nothing to carry
      if carry == 0 { break }
      (carry, bigger[i]) = Self.sub(bigger[i], carry)
    }

    assert(carry == 0)
  }

  private typealias PartialSubResult = (borrow: Word, result: Word)

  private static func sub(_ x: Word, _ y: Word) -> PartialSubResult {
    let (result, overflow) = x.subtractingReportingOverflow(y)
    let borrow: Word = overflow ? 1 : 0
    return (borrow, result)
  }

  private static func sub(_ x: Word, _ y: Word, _ z: Word) -> PartialSubResult {
    let (xy, overflow1) = x.subtractingReportingOverflow(y)
    let (xyz, overflow2) = xy.subtractingReportingOverflow(z)
    let borrow: Word = (overflow1 ? 1 : 0) + (overflow2 ? 1 : 0)
    return (borrow, xyz)
  }

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

    // If we have more words than 1 then we are our of range of smi
    guard heap.count == 1 else {
      return false
    }

    // We have the same sign and only 1 word in heap -> compare them
    let word = heap.data[0]
    let smiAbs = smi.value.magnitude
    return word == smiAbs
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

    // If we have more words than 1 then we are our of range of smi
    guard heap.count == 1 else {
      return true
    }

    // We have the same sign and only 1 word in heap -> compare them
    let word = heap.data[0]
    let smiAbs = smi.value.magnitude
    return word >= smiAbs
  }

  internal static func < (heap: BigIntHeap, smi: Smi) -> Bool {
    // Negative values are always smaller than positive ones (because math...)
    guard heap.isNegative == smi.isNegative else {
      return heap.isNegative
    }

    // If we have more words than 1 then we are our of range of smi
    guard heap.count == 1 else {
      return false
    }

    // We have the same sign and only 1 word in heap -> compare them
    let word = heap.data[0]
    let smiAbs = smi.value.magnitude
    return word < smiAbs
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
