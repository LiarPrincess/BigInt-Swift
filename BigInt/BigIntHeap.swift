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
  private let isNegative: Bool

  private var count: Int {
    return self.data.count
  }

  // MARK: - Init

  internal init(isNegative: Bool, word: Word) {
    self.isNegative = word == .zero ? false : isNegative
    self.data = [word]
  }

  internal init<T: BinaryInteger>(_ value: T) {
    self.isNegative = value < T.zero
    let magnitude = value.magnitude

    // We are assuming that there is no bigger unsigned 'int' than 'UInt64'.
    // Otherwise we would have to loop through 'value.words'
    guard let word = Word(exactly: magnitude) else {
      trap("\(T.self) is not (yet) supported in 'BigInt.init'")
    }

    self.data = [word]
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
    return lhs.data == rhs.data
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
}
