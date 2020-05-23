/// Small integer, named after similiar type in `V8`.
internal struct Smi:
  Comparable, CustomStringConvertible, CustomDebugStringConvertible {

  internal typealias Storage = Int32

  // MARK: - Static properties

  internal static var min: Storage {
    return Storage.min
  }

  internal static var max: Storage {
    return Storage.max
  }

  // MARK: - Properties

  internal let value: Storage

  internal var isZero: Bool {
    return self.value == .zero
  }

  internal var isNegative: Bool {
    return self.value < Storage(0)
  }

  /// Number of bits necessary to represent self in binary.
  /// `bitLength` in Python.
  internal var minRequiredWidth: Int {
    if self.value >= 0 {
      return Storage.bitWidth - self.value.leadingZeroBitCount
    }

    let sign = 1
    let inverted = ~self.value
    return Storage.bitWidth - inverted.leadingZeroBitCount + sign
  }

  // MARK: - Init

  internal init(_ value: Storage) {
    self.value = value
  }

  internal init?<T: BinaryInteger>(_ value: T) {
    guard let storage = Storage(exactly: value) else {
      return nil
    }

    self.value = storage
  }

  // MARK: - Unary operations

  internal var minus: BigInt {
    // Binary numbers have bigger range on the negative side.
    if self.value == Self.min {
      let magnitude = Self.min.magnitude
      let word = BigIntHeap.Word(magnitude)
      let heap = BigIntHeap(isNegative: false, word: word)
      return BigInt(heap)
    }

    return BigInt(smi: -self.value)
  }

  internal var inverted: BigInt {
    return BigInt(smi: ~self.value)
  }

  // MARK: - Add

  internal func add(other: Smi) -> BigInt {
    let (result, overflow) = self.value.addingReportingOverflow(other.value)
    if !overflow {
      return BigInt(smi: result)
    }

    // Binary numbers have bigger range on the negative side.
    // Special case, don't ask.
    if self.value == Storage.min && other.value == Storage.min {
      let min = BigIntHeap.Word(Storage.min.magnitude)
      let heap = BigIntHeap(isNegative: true, word: min << 1) // *2
      return BigInt(heap)
    }

    return self.handleAddSubOverflow(result: result)
  }

  private func handleAddSubOverflow(result: Storage) -> BigInt {
    // If we were positive:
    // - we only can overflow into positive values
    // - 'result' is negative, but it is value is exactly as we want,
    //    we just need it to treat as unsigned
    //
    // If we were negative:
    // - we only can overflow into negative values
    // - 'result' is positive, we have to 2 compliment it and treat as unsigned
    //
    // If we were zero:
    // - well... how did we overflow?

    let isNegative = self.isNegative

    let x = isNegative ? ((~result) &+ 1) : result
    let unsigned = Storage.Magnitude(bitPattern: x)
    let word = BigIntHeap.Word(unsigned)

    let heap = BigIntHeap(isNegative: isNegative, word: word)
    return BigInt(heap)
  }

  // MARK: - Sub

  internal func sub(other: Smi) -> BigInt {
    let (result, overflow) = self.value.subtractingReportingOverflow(other.value)
    if !overflow {
      return BigInt(smi: result)
    }

    return self.handleAddSubOverflow(result: result)
  }

  // MARK: - Mul

  // `1` at front, `0` for the rest
  private static let mostSignificantBitMask: Storage.Magnitude = {
    let shift = Storage.Magnitude.bitWidth - 1
    return 1 << shift
  }()

  /// `1` for all
  private static let allOneMask: Storage = {
    let allZero = Storage(0)
    return ~allZero
  }()

  internal func mul(other: Smi) -> BigInt {
    let (high, low) = self.value.multipliedFullWidth(by: other.value)

    // Normally we could obtain the result by
    // 'Int(high) << Storage.bitWidth | Int(low)',
    // but even without doing this we know if we are in 'Smi' range or not.

    // Positive smi
    if high == 0 && (low & Smi.mostSignificantBitMask) == 0 {
      let smi = Storage(bitPattern: low)
      return BigInt(smi: smi)
    }

    // Negative smi
    if high == Smi.allOneMask {
      let smi = Storage(bitPattern: low)
      return BigInt(smi: smi)
    }

    // Heap
    let result = Int(high) << Storage.bitWidth | Int(low)
    let heap = BigIntHeap(result)
    return BigInt(heap)
  }

  // MARK: - Div

  internal func div(other: Smi) -> BigInt {
    let (result, overflow) = self.value.dividedReportingOverflow(by: other.value)
    if !overflow {
      return BigInt(smi: result)
    }

    // AFAIK we can overflow in 2 cases:
    // - 'other' is 0 -> produce the same error as Swift
    // - 'Storage.min / -1' -> value 1 greater than Storage.max

    if other.value == 0 {
      _ = self.value / other.value // Well, hello there...
    }

    assert(self.value == Storage.min)
    assert(other.value == Storage(-1))
    let word = BigIntHeap.Word(Storage.max) + 1
    let heap = BigIntHeap(isNegative: false, word: word)
    return BigInt(heap)
  }

  // MARK: - Mod

  internal func mod(other: Smi) -> BigInt {
    let (result, overflow) =
      self.value.remainderReportingOverflow(dividingBy: other.value)

    if !overflow {
      return BigInt(smi: result)
    }

    // This has the same assumptions for overflow as 'div'.
    // Please check 'div' for details.

    if other.value == 0 {
      _ = self.value % other.value // Well, hello there...
    }

    assert(self.value == Storage.min)
    assert(other.value == Storage(-1))
    return BigInt(smi: 0)
  }

  // MARK: - Bit operations

  internal func and(other: Smi) -> BigInt {
    return BigInt(smi: self.value & other.value)
  }

  internal func or(other: Smi) -> BigInt {
    return BigInt(smi: self.value | other.value)
  }

  internal func xor(other: Smi) -> BigInt {
    return BigInt(smi: self.value ^ other.value)
  }

  // MARK: - String

  internal var description: String {
    return self.value.description
  }

  internal var debugDescription: String {
    return "Smi(\(self.value))"
  }

  internal func toString(radix: Int, uppercase: Bool) -> String {
    return String(self.value, radix: radix, uppercase: uppercase)
  }

  // MARK: - Equatable

  internal static func == (lhs: Smi, rhs: Smi) -> Bool {
    return lhs.value == rhs.value
  }

  // MARK: - Comparable

  internal static func < (lhs: Smi, rhs: Smi) -> Bool {
    return lhs.value < rhs.value
  }

  // MARK: - Strideable

  internal func distance(to other: Smi) -> BigInt {
    return other.sub(other: self)
  }

  internal func advanced(by n: Smi) -> BigInt {
    return self.add(other: n)
  }
}
