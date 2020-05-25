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
      self.sub(other: other.magnitude) // Just using '-' may overflow!
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

    if self.isNegative == other.isNegative {
      self.addSameSign(other: other)
      return
    }

    // Self positive, other negative: x + (-y) = x - y
    if self.isPositive {
      assert(other.isNegative)
      self.sub(other: other)
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
  /// Basically 1:1 copy from Swift code (see top of this file for link).
  private func addSameSign(other: BigIntHeap) {
    let commonCount = Swift.min(self.data.count, other.data.count)
    let maxCount = Swift.max(self.data.count, other.data.count)
    self.data.reserveCapacity(maxCount)

    // Add the words up to the common count, carrying any overflows
    var carry: Word = 0
    for i in 0..<commonCount {
      (carry, self.data[i]) = Self.add(self.data[i], other.data[i], carry)
    }

    // If there are leftover words in 'self', just need to handle any carries
    if self.data.count > other.data.count {
      for i in commonCount..<maxCount {
        // No more action needed if there's nothing to carry
        if carry == 0 { break }
        (carry, self.data[i]) = BigIntHeap.add(self.data[i], carry)
      }
    }
    // If there are leftover words in 'other', need to copy to 'self' with carries
    else {
      for i in commonCount..<maxCount {
        // Append remaining words if nothing to carry
        if carry == 0 {
          self.data.append(contentsOf: other.data.suffix(from: i))
          break
        }

        let partialResult: Word
        (carry, partialResult) = BigIntHeap.add(other.data[i], carry)
        self.data.append(partialResult)
      }
    }

    // If there's any carry left, add it now
    if carry != 0 {
      self.data.append(1)
    }

    // No need to fix invariants
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
    fatalError()
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

    // Shorter number is always smaller
    guard lhs.count == rhs.count else {
      return lhs.count < rhs.count
    }

    // Same sign and equal word count -> compare from most significant word
    let indices = stride(from: lhs.data.count, through: 0, by: -1)
    for index in indices {
      let lhsWord = lhs.data[index]
      let rhsWord = rhs.data[index]

      if lhsWord < rhsWord {
        return true
      }

      if lhsWord > rhsWord {
        return false
      }

      // Equal -> compare next words
    }

    return false
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
