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

  internal init(_ value: BigIntHeap) {
    self.value = .heap(value)
  }

  // MARK: - Unary operators

  public prefix static func + (value: BigInt) -> BigInt {
    return value
  }

  public static prefix func - (value: BigInt) -> BigInt {
    switch value.value {
    case let .smi(smi):
      return smi.minus
    case let .heap(heap):
      let copy = heap.copy()
      copy.negate()
      return copy.asNormalizedBigInt
    }
  }

  public prefix static func ~ (value: BigInt) -> BigInt {
    switch value.value {
    case let .smi(smi):
      return smi.inverted
    case let .heap(heap):
      let copy = heap.copy()
      copy.invert()
      return copy.asNormalizedBigInt
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
      copy.add(other: smi.value)
      return copy.asNormalizedBigInt

    case let (.heap(lhs), .heap(rhs)):
      let copy = lhs.copy()
      copy.add(other: rhs)
      return copy.asNormalizedBigInt
    }
  }

  // TODO: If we are heap, them maybe we can downgrade?

  public static func += (lhs: inout BigInt, rhs: BigInt) {
    switch (lhs.value, rhs.value) {
    case let (.smi(lhsSmi), .smi(rhs)):
      let result = lhsSmi.add(other: rhs)
      lhs.value = result.value

    case let (.smi(lhsSmi), .heap(rhs)):
      // Unfortunately in this case we have to copy rhs
      let rhsCopy = rhs.copy()
      rhsCopy.add(other: lhsSmi.value)
      lhs.value = .heap(rhsCopy)

    case let (.heap(lhs), .smi(rhs)):
      lhs.add(other: rhs.value)

    case let (.heap(lhs), .heap(rhs)):
      lhs.add(other: rhs)
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
      rhsCopy.add(other: lhs.value)
      return rhsCopy.asNormalizedBigInt

    case let (.heap(lhs), .smi(rhs)):
      let copy = lhs.copy()
      copy.sub(other: rhs.value)
      return copy.asNormalizedBigInt

    case let (.heap(lhs), .heap(rhs)):
      let copy = lhs.copy()
      copy.sub(other: rhs)
      return copy.asNormalizedBigInt
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
      rhsCopy.add(other: lhsSmi.value)
      lhs.value = .heap(rhsCopy)

    case let (.heap(lhs), .smi(rhs)):
      lhs.sub(other: rhs.value)

    case let (.heap(lhs), .heap(rhs)):
      lhs.sub(other: rhs)
    }
  }

  // MARK: - Add/sub to remove

  // Not needed if we conform to Binary int
  public static func +<T: BinaryInteger> (lhs: BigInt, rhs: T) -> BigInt { fatalError() }
  public static func -<T: BinaryInteger> (lhs: BigInt, rhs: T) -> BigInt { fatalError() }

  // TODO: In mul check for special case of 0, 1 and -1

  // MARK: - Shift

  internal func shiftLeft<T: BinaryInteger>(count: T) -> BigInt {
    switch self.value {
    case let .smi(smi):
      return smi.shiftLeft(count: count)
    case let .heap(heap):
      trap("")
    }
  }

  internal func shiftLeft(count: BigInt) -> BigInt {
    let normalized = count.normalized()

    switch normalized.value {
    case let .smi(smi):
      return self.shiftLeft(count: smi.value)
    case let .heap(heap):
      trap("Shifting by \(heap) is not supported.")
    }
  }

  internal func shiftRight<T: BinaryInteger>(count: T) -> BigInt {
    switch self.value {
    case let .smi(smi):
      return smi.shiftRight(count: count)
    case let .heap(heap):
      trap("")
    }
  }

  internal func shiftRight(count: BigInt) -> BigInt {
    let normalized = count.normalized()

    switch normalized.value {
    case let .smi(smi):
      return self.shiftRight(count: smi.value)
    case let .heap(heap):
      trap("Shifting by \(heap) is not supported.")
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

  internal var bin: String {
    return self.toString(radix: 2, uppercase: false)
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

  // MARK: - Normalization

  /// Convert to `smi` if possible.
  private func normalized() -> BigInt {
    switch self.value {
    case .smi:
      return self
    case .heap(let heap):
      return heap.asNormalizedBigInt
    }
  }
}
