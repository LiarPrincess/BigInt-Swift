// swiftlint:disable file_length

internal struct BigIntNew {

  internal enum Storage {
    case smi(Smi)
    case heap(BigIntHeapNew)
  }

  internal private(set) var value: Storage

  /// This will downgrade to `Smi` if possible
  internal init(_ value: BigIntHeapNew) {
    self.value = .heap(value)
  }
}

internal struct BigIntHeapNew: Equatable, ExpressibleByIntegerLiteral {

  internal typealias Word = BigIntStorage.Word

  // MARK: - Properties

  private var storage: BigIntStorage

  private var isZero: Bool {
    return self.storage.isZero
  }

  /// `0` is also positive.
  private var isPositive: Bool {
    return !self.isNegative
  }

  private var isNegative: Bool {
    return self.storage.isNegative
  }

  private var count: Int {
    return self.storage.count
  }

  internal var words: BigIntStorage {
    // We will return 'BigIntStorage' to save allocation in some cases.
    // But remember that in this case it will be used as collection,
    // that means that eny additional data (sign etc.) will be ignored.

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

    // At this point our 'storage' holds positive number, so we have 2 complement it.
    var copy = self.storage
    copy.transformEveryWord(fn: ~) // Invert every word
    Self.addMagnitude(lhs: &copy, rhs: 1)
    return copy
  }

  /// The minimum number of bits required to represent this integer in binary.
  internal var bitWidth: Int {
    guard let last = self.storage.last else {
      assert(self.isZero)
      return 0
    }

    let sign = 1
    return self.count * Word.bitWidth - last.leadingZeroBitCount + sign
  }

  /// The number of trailing zero bits in the binary representation of this integer.
  ///
  /// - Important:
  /// `0` is considered to have zero trailing zero bits.
  internal var trailingZeroBitCount: Int {
    if let index = self.storage.lastIndex(where: { $0 != 0 }) {
      let word = self.storage[index]
      return index * Word.bitWidth + word.trailingZeroBitCount
    }

    assert(self.isZero)
    return 0
  }

  internal var minRequiredWidth: Int {
    return self.bitWidth
  }

  internal var magnitude: BigIntNew {
    if self.isPositive {
      return BigIntNew(self)
    }

    var abs = self
    abs.negate()
    assert(abs.isPositive)
    return abs.magnitude
  }

  // MARK: - Init

  /// Init with storage set to `0`.
  private init() {
    self.storage = BigIntStorage(minimumCapacity: 0)
  }

  private init(minimumStorageCapacity: Int) {
    self.storage = BigIntStorage(minimumCapacity: minimumStorageCapacity)
  }

  internal init<T: BinaryInteger>(_ value: T) {
    self.init(minimumStorageCapacity: 1)

    if !value.isZero {
      let word = Word(value.magnitude)
      self.storage.append(word)

      if value.isNegative {
        self.storage.isNegative.toggle()
      }
    }

    self.storage.checkInvariants()
  }

  internal init(integerLiteral value: Int) {
    self.init(value)
  }

  // Source:
  // https://github.com/benrimmington/swift-numerics/blob/BigInt/Sources/BigIntModule/BigInt.swift
  internal init<T: BinaryFloatingPoint>(_ source: T) {
    precondition(
      source.isFinite,
      "\(type(of: source)) value cannot be converted to BigInt because it is either infinite or NaN"
    )

    if source.isZero {
      self.init()
      return
    }

    var float = source < .zero ? -source : source
    if float < 1.0 {
      self.init()
      return
    }

    self.init(minimumStorageCapacity: 4)

    let radix = T(sign: .plus, exponent: T.Exponent(Word.bitWidth), significand: 1)
    repeat {
      let word = Word(float.truncatingRemainder(dividingBy: radix))
      self.storage.append(word)
      float = (float / radix).rounded(.towardZero)
    } while !float.isZero

    if source < .zero {
      self.storage.isNegative = true
    }

    self.storage.checkInvariants()
  }

  internal init?<T: BinaryFloatingPoint>(exactly source: T) {
    guard source.isFinite else {
      return nil
    }

    guard source == source.rounded(.towardZero) else {
      return nil
    }

    self.init(source)
  }

  // MARK: - Unary

  internal mutating func negate() {
    // Zero is always positive
    if self.isZero {
      assert(self.isPositive)
      return
    }

    self.storage.isNegative.toggle()
    self.storage.checkInvariants()
  }

  internal mutating func invert() {
    self.add(other: 1)
    self.negate()
    self.storage.checkInvariants()
  }

  // MARK: - Add

  private mutating func add(other: Smi.Storage) { }

  // MARK: - Equatable

  internal static func == (heap: BigIntHeapNew, smi: Smi) -> Bool {
    // Different signs are never equal
    guard heap.isNegative == smi.isNegative else {
      return false
    }

    let lhs = heap.storage
    let rhs = Word(smi.value.magnitude)
    switch Self.compareMagnitudes(lhs: lhs, rhs: rhs) {
    case .equal:
      return true
    case .less,
         .greater:
      return false
    }
  }

  internal static func == (lhs: BigIntHeapNew, rhs: BigIntHeapNew) -> Bool {
    return lhs.storage == rhs.storage
  }

  // MARK: - Comparable

  internal static func >= (heap: BigIntHeapNew, smi: Smi) -> Bool {
    // Negative values are always smaller than positive ones (because math...)
    guard heap.isNegative == smi.isNegative else {
      return smi.isNegative
    }

    let lhs = heap.storage
    let rhs = Word(smi.value.magnitude)
    switch Self.compareMagnitudes(lhs: lhs, rhs: rhs) {
    case .equal,
         .greater:
      return true
    case .less:
      return false
    }
  }

  internal static func < (heap: BigIntHeapNew, smi: Smi) -> Bool {
    // Negative values are always smaller than positive ones (because math...)
    guard heap.isNegative == smi.isNegative else {
      return heap.isNegative
    }

    let lhs = heap.storage
    let rhs = Word(smi.value.magnitude)
    switch Self.compareMagnitudes(lhs: lhs, rhs: rhs) {
    case .less:
      return true
    case .equal,
         .greater:
      return false
    }
  }

  internal static func < (lhs: BigIntHeapNew, rhs: BigIntHeapNew) -> Bool {
    // Negative values are always smaller than positive ones (because math...)
    guard lhs.isNegative == rhs.isNegative else {
      return lhs.isNegative
    }

    switch Self.compareMagnitudes(lhs: lhs.storage, rhs: rhs.storage) {
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

  private static func compareMagnitudes(lhs: BigIntStorage,
                                        rhs: Word) -> CompareMagnitudes {
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

  private static func compareMagnitudes(lhs: BigIntStorage,
                                        rhs: BigIntStorage) -> CompareMagnitudes {
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
}
