// swiftlint:disable file_length

// TODO: Docs

public struct BigInt:
  SignedInteger, // Strideable
  Comparable, Hashable,
  CustomStringConvertible, CustomDebugStringConvertible {

  // MARK: - Helper types

  internal enum Storage {
    case smi(Smi)
    case heap(BigIntHeap)
  }

  public struct Words: RandomAccessCollection {

    // swiftlint:disable:next nesting
    private enum Inner {
      case smi(Smi.Words)
      case heap(BigIntHeap.Words)
    }

    private let inner: Inner

    fileprivate init(_ value: BigInt) {
      switch value.value {
      case let .smi(smi):
        self.inner = .smi(smi.words)
      case let .heap(heap):
        self.inner = .heap(heap.words)
      }
    }

    public var count: Int {
      switch self.inner {
      case let .smi(smi):
        return smi.count
      case let .heap(heap):
        return heap.count
      }
    }

    public var indices: Indices {
      return 0..<self.count
    }

    public var startIndex: Int {
      return 0
    }

    public var endIndex: Int {
      return self.count
    }

    public subscript(_ index: Int) -> UInt {
      switch self.inner {
      case let .smi(smi):
        return smi[index]
      case let .heap(heap):
        return heap[index]
      }
    }
  }

  // MARK: - Properties

  internal private(set) var value: Storage

  public var words: Words {
    return Words(self)
  }

  public var bitWidth: Int {
    switch self.value {
    case let .smi(smi):
      return smi.bitWidth
    case let .heap(heap):
      return heap.bitWidth
    }
  }

  public var trailingZeroBitCount: Int {
    switch self.value {
    case let .smi(smi):
      return smi.trailingZeroBitCount
    case let .heap(heap):
      return heap.trailingZeroBitCount
    }
  }

  // TODO: minRequiredWidth

  public var magnitude: BigInt {
    switch self.value {
    case let .smi(smi):
      return smi.magnitude
    case let .heap(heap):
      return heap.magnitude
    }
  }

  // MARK: - Init

  public init() {
    self.value = .smi(Smi(0))
  }

  public init<T: BinaryInteger>(_ value: T) {
    if let smi = Smi(value) {
      self.value = .smi(smi)
    } else {
      let heap = BigIntHeap(value)
      self.value = .heap(heap)
    }
  }

  public init(integerLiteral value: Int) {
    self.init(value)
  }

  public init?<T: BinaryInteger>(exactly source: T) {
    self.init(source)
  }

  public init<T: BinaryInteger>(truncatingIfNeeded source: T) {
    self.init(source)
  }

  public init<T: BinaryInteger>(clamping source: T) {
    self.init(source)
  }

  public init<T: BinaryFloatingPoint>(_ source: T) {
    let heap = BigIntHeap(source)
    self.value = .heap(heap)
    self.downgradeToSmiIfPossible()
  }

  public init?<T: BinaryFloatingPoint>(exactly source: T) {
    guard let heap = BigIntHeap(exactly: source) else {
      return nil
    }

    self.value = .heap(heap)
    self.downgradeToSmiIfPossible()
  }

  internal init(smi value: Smi.Storage) {
    self.value = .smi(Smi(value))
  }

  /// This will downgrade to `Smi` if possible
  internal init(_ value: BigIntHeap) {
    self.value = .heap(value)
    self.downgradeToSmiIfPossible()
  }

  // MARK: - Downgrade

  private mutating func downgradeToSmiIfPossible() {
    switch self.value {
    case .smi:
      break
    case .heap(let heap):
      if let smi = heap.asSmiIfPossible() {
        self.value = .smi(smi)
      }
    }
  }

  // MARK: - Unary operators

  public prefix static func + (value: BigInt) -> BigInt {
    return value
  }

  public static prefix func - (value: BigInt) -> BigInt {
    switch value.value {
    case let .smi(smi):
      return smi.negated
    case let .heap(heap):
      let copy = heap.copy()
      copy.negate()
      return BigInt(copy)
    }
  }

  public prefix static func ~ (value: BigInt) -> BigInt {
    switch value.value {
    case let .smi(smi):
      return smi.inverted
    case let .heap(heap):
      let copy = heap.copy()
      copy.invert()
      return BigInt(copy)
    }
  }

  // MARK: - Add

  public static func + (lhs: BigInt, rhs: BigInt) -> BigInt {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhs), .smi(rhs)):
      return lhs.add(other: rhs)

    case let (.smi(smi), .heap(heap)),
         let (.heap(heap), .smi(smi)):
      let copy = heap.copy()
      copy.add(other: smi)
      return BigInt(copy)

    case let (.heap(lhs), .heap(rhs)):
      let copy = lhs.copy()
      copy.add(other: rhs)
      return BigInt(copy)
    }
  }

  public static func += (lhs: inout BigInt, rhs: BigInt) {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhsSmi), .smi(rhs)):
      let result = lhsSmi.add(other: rhs)
      lhs.value = result.value

    case let (.smi(lhsSmi), .heap(rhs)):
      // Unfortunately in this case we have to copy 'rhs'
      let rhsCopy = rhs.copy()
      rhsCopy.add(other: lhsSmi)
      lhs.value = .heap(rhsCopy)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .smi(rhs)):
      lhsHeap.add(other: rhs)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .heap(rhs)):
      lhsHeap.add(other: rhs)
      lhs.downgradeToSmiIfPossible()
    }
  }

  // MARK: - Sub

  public static func - (lhs: BigInt, rhs: BigInt) -> BigInt {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhs), .smi(rhs)):
      return lhs.sub(other: rhs)

    case let (.smi(lhs), .heap(rhs)):
      // x - y = x + (-y) = (-y) + x
      let rhsCopy = rhs.copy()
      rhsCopy.negate()
      rhsCopy.add(other: lhs)
      return BigInt(rhsCopy)

    case let (.heap(lhs), .smi(rhs)):
      let copy = lhs.copy()
      copy.sub(other: rhs)
      return BigInt(copy)

    case let (.heap(lhs), .heap(rhs)):
      let copy = lhs.copy()
      copy.sub(other: rhs)
      return BigInt(copy)
    }
  }

  public static func -= (lhs: inout BigInt, rhs: BigInt) {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhsSmi), .smi(rhs)):
      let result = lhsSmi.sub(other: rhs)
      lhs.value = result.value

    case let (.smi(lhsSmi), .heap(rhs)):
      // Unfortunately in this case we have to copy rhs
      // x - y = x + (-y) = (-y) + x
      let rhsCopy = rhs.copy()
      rhsCopy.negate()
      rhsCopy.add(other: lhsSmi)
      lhs.value = .heap(rhsCopy)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .smi(rhs)):
      lhsHeap.sub(other: rhs)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .heap(rhs)):
      lhsHeap.sub(other: rhs)
      lhs.downgradeToSmiIfPossible()
    }
  }

  // MARK: - Mul

  public static func * (lhs: BigInt, rhs: BigInt) -> BigInt {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhs), .smi(rhs)):
      return lhs.mul(other: rhs)

    case let (.smi(smi), .heap(heap)),
         let (.heap(heap), .smi(smi)):
      let heapCopy = heap.copy()
      heapCopy.mul(other: smi)
      return BigInt(heapCopy)

    case let (.heap(lhs), .heap(rhs)):
      let copy = lhs.copy()
      copy.mul(other: rhs)
      return BigInt(copy)
    }
  }

  public static func *= (lhs: inout BigInt, rhs: BigInt) {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhsSmi), .smi(rhs)):
      let result = lhsSmi.mul(other: rhs)
      lhs.value = result.value

    case let (.smi(lhsSmi), .heap(rhs)):
      // Unfortunately in this case we have to copy rhs
      let rhsCopy = rhs.copy()
      rhsCopy.mul(other: lhsSmi)
      lhs.value = .heap(rhsCopy)
      lhs.downgradeToSmiIfPossible() // probably not

    case let (.heap(lhsHeap), .smi(rhs)):
      lhsHeap.mul(other: rhs)
      lhs.downgradeToSmiIfPossible() // probably not

    case let (.heap(lhsHeap), .heap(rhs)):
      lhsHeap.mul(other: rhs)
      lhs.downgradeToSmiIfPossible() // probably not
    }
  }

  // MARK: - Div

  public static func / (lhs: BigInt, rhs: BigInt) -> BigInt {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhs), .smi(rhs)):
      return lhs.div(other: rhs)

    case let (.smi(lhsSmi), .heap(rhs)):
      let lhsHeap = BigIntHeap(lhsSmi.value)
      lhsHeap.div(other: rhs)
      return BigInt(lhsHeap)

    case let (.heap(heap), .smi(smi)):
      let heapCopy = heap.copy()
      heapCopy.div(other: smi)
      return BigInt(heapCopy)

    case let (.heap(lhs), .heap(rhs)):
      let copy = lhs.copy()
      copy.div(other: rhs)
      return BigInt(copy)
    }
  }

  public static func /= (lhs: inout BigInt, rhs: BigInt) {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhsSmi), .smi(rhs)):
      let result = lhsSmi.div(other: rhs)
      lhs.value = result.value

    case let (.smi(lhsSmi), .heap(rhs)):
      let lhsHeap = BigIntHeap(lhsSmi.value)
      lhsHeap.div(other: rhs)
      lhs.value = .heap(lhsHeap)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .smi(rhs)):
      lhsHeap.div(other: rhs)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .heap(rhs)):
      lhsHeap.div(other: rhs)
      lhs.downgradeToSmiIfPossible()
    }
  }

  // MARK: - Mod

  public static func % (lhs: BigInt, rhs: BigInt) -> BigInt {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhs), .smi(rhs)):
      return lhs.mod(other: rhs)

    case let (.smi(lhsSmi), .heap(rhs)):
      let lhsHeap = BigIntHeap(lhsSmi.value)
      lhsHeap.mod(other: rhs)
      return BigInt(lhsHeap)

    case let (.heap(heap), .smi(smi)):
      let heapCopy = heap.copy()
      heapCopy.mod(other: smi)
      return BigInt(heapCopy)

    case let (.heap(lhs), .heap(rhs)):
      let copy = lhs.copy()
      copy.mod(other: rhs)
      return BigInt(copy)
    }
  }

  public static func %= (lhs: inout BigInt, rhs: BigInt) {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhsSmi), .smi(rhs)):
      let result = lhsSmi.mod(other: rhs)
      lhs.value = result.value

    case let (.smi(lhsSmi), .heap(rhs)):
      let lhsHeap = BigIntHeap(lhsSmi.value)
      lhsHeap.mod(other: rhs)
      lhs.value = .heap(lhsHeap)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .smi(rhs)):
      lhsHeap.mod(other: rhs)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .heap(rhs)):
      lhsHeap.mod(other: rhs)
      lhs.downgradeToSmiIfPossible()
    }
  }

  // MARK: - Div mod

  public typealias DivMod = (quotient: BigInt, remainder: BigInt)

  // TODO: Move all promotions to BigIntHeap, search for 'BigIntHeap('
  // TODO: Use this in Violet
  public func divMod(other: BigInt) -> DivMod {
    switch (self.value, other.value) {
    case let (.smi(lhs), .smi(rhs)):
      // This is so cheap that we can do it in a trivial way
      let quotient = lhs.div(other: rhs)
      let remainder = lhs.mod(other: rhs)
      return (quotient: quotient, remainder: remainder)

    case let (.smi(lhs), .heap(rhs)):
      // We need to promote 'lhs' to heap
      let lhsHeap = BigIntHeap(lhs.value)
      return self.divMod(lhs: lhsHeap, rhs: rhs)

    case let (.heap(lhs), .smi(rhs)):
      // We need to promote 'rhs' to heap
      let rhsHeap = BigIntHeap(rhs.value)
      return self.divMod(lhs: lhs, rhs: rhsHeap)

    case let (.heap(lhs), .heap(rhs)):
      return self.divMod(lhs: lhs, rhs: rhs)
    }
  }

  private func divMod(lhs: BigIntHeap, rhs: BigIntHeap) -> DivMod {
    let result = BigIntHeap.divMod(lhs: lhs, rhs: rhs)
    let quotient = BigInt(result.quotient)
    let remainder = BigInt(result.remainder)
    return (quotient: quotient, remainder: remainder)
  }

  // MARK: - And

  public static func & (lhs: BigInt, rhs: BigInt) -> BigInt {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhs), .smi(rhs)):
      return lhs.and(other: rhs)

    case let (.smi(smi), .heap(heap)),
         let (.heap(heap), .smi(smi)):
      let heapCopy = heap.copy()
      heapCopy.and(other: smi)
      return BigInt(heapCopy)

    case let (.heap(lhs), .heap(rhs)):
      let copy = lhs.copy()
      copy.and(other: rhs)
      return BigInt(copy)
    }
  }

  public static func &= (lhs: inout BigInt, rhs: BigInt) {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhsSmi), .smi(rhs)):
      let result = lhsSmi.and(other: rhs)
      lhs.value = result.value

    case let (.smi(lhsSmi), .heap(rhs)):
      let lhsHeap = BigIntHeap(lhsSmi.value)
      lhsHeap.and(other: rhs)
      lhs.value = .heap(lhsHeap)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .smi(rhs)):
      lhsHeap.and(other: rhs)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .heap(rhs)):
      lhsHeap.and(other: rhs)
      lhs.downgradeToSmiIfPossible()
    }
  }

  // MARK: - Or

  public static func | (lhs: BigInt, rhs: BigInt) -> BigInt {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhs), .smi(rhs)):
      return lhs.or(other: rhs)

    case let (.smi(smi), .heap(heap)),
         let (.heap(heap), .smi(smi)):
      let heapCopy = heap.copy()
      heapCopy.or(other: smi)
      return BigInt(heapCopy)

    case let (.heap(lhs), .heap(rhs)):
      let copy = lhs.copy()
      copy.or(other: rhs)
      return BigInt(copy)
    }
  }

  public static func |= (lhs: inout BigInt, rhs: BigInt) {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhsSmi), .smi(rhs)):
      let result = lhsSmi.or(other: rhs)
      lhs.value = result.value

    case let (.smi(lhsSmi), .heap(rhs)):
      let lhsHeap = BigIntHeap(lhsSmi.value)
      lhsHeap.or(other: rhs)
      lhs.value = .heap(lhsHeap)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .smi(rhs)):
      lhsHeap.or(other: rhs)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .heap(rhs)):
      lhsHeap.or(other: rhs)
      lhs.downgradeToSmiIfPossible()
    }
  }

  // MARK: - Xor

  public static func ^ (lhs: BigInt, rhs: BigInt) -> BigInt {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhs), .smi(rhs)):
      return lhs.xor(other: rhs)

    case let (.smi(smi), .heap(heap)),
         let (.heap(heap), .smi(smi)):
      let heapCopy = heap.copy()
      heapCopy.xor(other: smi)
      return BigInt(heapCopy)

    case let (.heap(lhs), .heap(rhs)):
      let copy = lhs.copy()
      copy.xor(other: rhs)
      return BigInt(copy)
    }
  }

  public static func ^= (lhs: inout BigInt, rhs: BigInt) {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhsSmi), .smi(rhs)):
      let result = lhsSmi.xor(other: rhs)
      lhs.value = result.value

    case let (.smi(lhsSmi), .heap(rhs)):
      let lhsHeap = BigIntHeap(lhsSmi.value)
      lhsHeap.xor(other: rhs)
      lhs.value = .heap(lhsHeap)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .smi(rhs)):
      lhsHeap.xor(other: rhs)
      lhs.downgradeToSmiIfPossible()

    case let (.heap(lhsHeap), .heap(rhs)):
      lhsHeap.xor(other: rhs)
      lhs.downgradeToSmiIfPossible()
    }
  }

  // MARK: - Shift left

  public static func << <T: BinaryInteger>(lhs: BigInt, rhs: T) -> BigInt {
    switch lhs.value {
    case let .smi(smi):
      return smi.shiftLeft(count: rhs)
    case let .heap(heap):
      let copy = heap.copy()
      copy.shiftLeft(count: rhs)
      return BigInt(copy)
    }
  }

  public static func <<= <T: BinaryInteger>(lhs: inout BigInt, rhs: T) {
    switch lhs.value {
    case let .smi(smi):
      let result = smi.shiftLeft(count: rhs)
      lhs.value = result.value
    case let .heap(heap):
      heap.shiftLeft(count: rhs)
    }
  }

  // MARK: - Shift right

  public static func >> <T: BinaryInteger>(lhs: BigInt, rhs: T) -> BigInt {
    switch lhs.value {
    case let .smi(smi):
      return smi.shiftRight(count: rhs)
    case let .heap(heap):
      let copy = heap.copy()
      copy.shiftRight(count: rhs)
      return BigInt(copy)
    }
  }

  public static func >>= <T: BinaryInteger>(lhs: inout BigInt, rhs: T) {
    switch lhs.value {
    case let .smi(smi):
      let result = smi.shiftRight(count: rhs)
      lhs.value = result.value
    case let .heap(heap):
      heap.shiftRight(count: rhs)
    }
  }

  // MARK: - String

  public var description: String {
    switch self.value {
    case let .smi(smi):
      return smi.description
    case let .heap(heap):
      return heap.description
    }
  }

  public var debugDescription: String {
    switch self.value {
    case let .smi(smi):
      return smi.debugDescription
    case let .heap(heap):
      return heap.debugDescription
    }
  }

  // 'toString' because we Java now
  internal func toString(radix: Int, uppercase: Bool) -> String {
    precondition(2 <= radix && radix <= 36, "radix must be in range 2...36")
    switch self.value {
    case let .smi(smi):
      return smi.toString(radix: radix, uppercase: uppercase)
    case let .heap(heap):
      return heap.toString(radix: radix, uppercase: uppercase)
    }
  }

  // MARK: - Equatable

  public static func == (lhs: BigInt, rhs: BigInt) -> Bool {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhs), .smi(rhs)):
      return lhs == rhs
    case let (.smi(smi), .heap(heap)),
         let (.heap(heap), .smi(smi)):
      return heap == smi
    case let (.heap(lhs), .heap(rhs)):
      return lhs == rhs
    }
  }

  // MARK: - Comparable

  public static func < (lhs: BigInt, rhs: BigInt) -> Bool {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhs), .smi(rhs)):
      return lhs < rhs
    case let (.smi(smi), .heap(heap)):
      return heap >= smi
    case let (.heap(heap), .smi(smi)):
      return heap < smi
    case let (.heap(lhs), .heap(rhs)):
      return lhs < rhs
    }
  }

  // MARK: - Hashable

  public func hash(into hasher: inout Hasher) {
    switch self.value {
    case let .smi(smi):
      smi.hash(into: &hasher)
    case let .heap(heap):
      heap.hash(into: &hasher)
    }
  }
}
