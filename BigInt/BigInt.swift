public struct BigInt: Comparable, CustomStringConvertible, CustomDebugStringConvertible {

  internal enum Storage {
    case inline(Smi)
    case heap(BigIntHeap)
  }

  public static func checkInvariants() {
    guard MemoryLayout<BigInt>.stride == 8 else {
      trap("[BigInt] Expected 'BigInt' to have 8 bytes.")
    }

    guard Int.bitWidth > Smi.Storage.bitWidth else {
      trap("[BigInt] Expected native 'Int' to be wider than 'Smi'.")
    }
  }

  // MARK: - Properties

  internal let value: Storage

  // MARK: - Init

  public init() {
    self.value = .inline(Smi(0))
  }

  internal init<T: BinaryInteger>(_ value: T) {
    if let smi = Smi(value) {
      self.value = .inline(smi)
    } else {
      let heap = BigIntHeap(value)
      self.value = .heap(heap)
    }
  }

  internal init(smi value: Smi.Storage) {
    self.value = .inline(Smi(value))
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
    case let .inline(smi):
      return smi.minus
    case let .heap(heap):
      trap("")
    }
  }

  public prefix static func ~ (value: BigInt) -> BigInt {
    switch value.value {
    case let .inline(smi):
      return smi.inverted
    case let .heap(heap):
      trap("")
    }
  }

  // MARK: - String

  public var description: String {
    switch self.value {
    case let .inline(smi):
      return smi.description
    case let .heap(heap):
      return heap.description
    }
  }

  public var debugDescription: String {
    switch self.value {
    case let .inline(smi):
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
    case let .inline(smi):
      return smi.toString(radix: radix, uppercase: uppercase)
    case let .heap(heap):
      return heap.toString(radix: radix, uppercase: uppercase)
    }
  }

  // MARK: - Equatable

  public static func == (lhs: BigInt, rhs: BigInt) -> Bool {
    switch (lhs.value, rhs.value) {
    case let (.inline(lhs), .inline(rhs)):
      return lhs == rhs
    case let (.inline(smi), .heap(heap)),
         let (.heap(heap), .inline(smi)):
      return heap == smi
    case let (.heap(lhs), .heap(rhs)):
      return lhs == rhs
    }
  }

  // MARK: - Comparable

  public static func < (lhs: BigInt, rhs: BigInt) -> Bool {
    switch (lhs.value, rhs.value) {
    case let (.inline(lhs), .inline(rhs)):
      return lhs < rhs
    case let (.inline(smi), .heap(heap)):
      return heap >= smi
    case let (.heap(heap), .inline(smi)):
      return heap < smi
    case let (.heap(lhs), .heap(rhs)):
      return lhs < rhs
    }
  }
}
