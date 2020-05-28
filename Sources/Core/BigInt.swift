// swiftlint:disable file_length

public struct BigInt: Comparable, CustomStringConvertible, CustomDebugStringConvertible {

  internal enum Storage {
    case smi(Smi)
    case heap(BigIntHeap)
  }

  // TODO: Old 'checkInvariants'
//  public static func checkInvariants() {
//    guard MemoryLayout<BigInt>.stride == 8 else {
//      trap("[BigInt] Expected 'BigInt' to have 8 bytes.")
//    }
//
//    guard Int.bitWidth > Smi.Storage.bitWidth else {
//      trap("[BigInt] Expected native 'Int' to be wider than 'Smi'.")
//    }
//  }

  // MARK: - Properties

  internal private(set) var value: Storage

  // MARK: - Init

  public init() {
    self.value = .smi(Smi(0))
  }

  internal init<T: BinaryInteger>(_ value: T) {
    if let smi = Smi(value) {
      self.value = .smi(smi)
    } else {
      let heap = BigIntHeap(value)
      self.value = .heap(heap)
    }
  }

  internal init(smi value: Smi.Storage) {
    self.value = .smi(Smi(value))
  }

  internal init(_ value: Smi) {
    self.value = .smi(value)
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

  // TODO: String(radix:)
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
}