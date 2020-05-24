// A lot of this code was taken from:
// https://github.com/apple/swift/blob/master/test/Prototypes/BigInt.swift

// TODO: Make it struct and store pointer to buffer, value at 0 will be count
internal class BigIntHeap: Comparable, CustomStringConvertible, CustomDebugStringConvertible {

  internal typealias Word = UInt64

  // MARK: - Properties

  /// The binary representation of the value's magnitude,
  /// with the least significant word at index `0`.
  ///
  /// - `data` has no trailing zero elements
  /// - If `self == 0`, then `isNegative == false` and `data == []`
  private let data: [Word]

  /// A Boolean value indicating whether this instance is negative.
  internal let isNegative: Bool

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
  }

  internal init(isNegative: Bool, data _data: [Word]) {
    let data = Self.trimPrefixZeros(data: _data)

    // Zero is always positive
    self.isNegative = data.isEmpty ? false : isNegative
    self.data = data
  }

  private static func trimPrefixZeros(data: [Word]) -> [Word] {
    // Empty -> return empty
    guard let last = data.last else {
      return data
    }

    // If last is not 0 -> no trimming needed
    if !last.isZero {
      return data
    }

    // Go from the back and try to find non zero
    if let lastNonZeroIndex = data.lastIndex(where: { !$0.isZero }) {
      let result = data[0...lastNonZeroIndex]
      return Array(result)
    }

    // All are 0
    return []
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
  }

  // MARK: - Unary operations

  /// Guaranteed to never allocate new array
  internal var minus: BigInt {
    if self.isZero {
      return BigInt(self)
    }

    let heap = BigIntHeap(isNegative: !self.isNegative, data: self.data)
    return BigInt(heap)
  }

  internal var inverted: BigInt {
    // -x - 1
    let minusSelf = self.minus
    return minusSelf - 1
  }

  // MARK: - Add

  // TODO: We can go back to smi if we are going down!

  internal func add<T: BinaryInteger>(other: T) -> BigInt {
    if other.isZero {
      return BigInt(self)
    }

    if self.isZero {
      return BigInt(other)
    }

    // Same sign
    if self.isNegative == other.isNegative {
      return self.addSameSign(other: other)
    }

    // Self positive, other negative: x + (-y) = x - y
    if other.isNegative {
      assert(self.isPositive)
      // Just using '-' may overflow!
      return self.sub(other: other.magnitude)
    }

    // Self negative, other positive:  -x + y = -(x - y)
    assert(self.isNegative && other.isPositive)
    let minusSelf = self.minus
    let partial = minusSelf - other
    return -partial
  }

  /// Both are positive or both are negative.
  private func addSameSign<T: BinaryInteger>(other _other: T) -> BigInt {
    // swiftlint:disable:next empty_count
    assert(self.data.count != 0, "0 should be handled earlier")
    let other = Word(_other.magnitude)

    var carry: Word
    var data = self.data
    (carry, data[0]) = Self.add(data[0], other)

    for i in 1..<data.count {
      guard carry > 0 else {
        break
      }

      (carry, data[i]) = Self.add(data[i], other)
    }

    if carry > 0 {
      data.append(1)
    }

    let heap = BigIntHeap(isNegative: self.isNegative, data: data)
    return BigInt(heap)
  }

  internal func add(other: BigIntHeap) -> BigInt {
    fatalError()
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

  internal func sub<T: BinaryInteger>(other: T) -> BigInt {
    fatalError()
  }

  internal func sub(other: BigIntHeap) -> BigInt {
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

  // MARK: - Check invariants

  // TODO: Uncomment 'checkInvariants'
//  private func checkInvariants(source: StaticString = #function) {
//    if let last = self.data.last {
//      assert(last != 0, "\(source): zero prefix in BigInt")
//    } else {
//      // 'self.data' is empty
//      assert(self.isNegative == false, "\(source): isNegative with empty data")
//    }
//  }

  // MARK: - As smi

  internal func asSmiIfPossible() -> Smi? {
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
