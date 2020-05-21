public struct BigInt: Comparable, CustomStringConvertible, CustomDebugStringConvertible {

  internal enum Storage {
    case inline(Smi)
    case heap(BigIntHeap)
  }

  // MARK: - Properties

  private let value: Storage

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
      fatalError()
    }
  }

  public prefix static func ~ (value: BigInt) -> BigInt {
    switch value.value {
    case let .inline(smi):
      return smi.inverted
    case let .heap(heap):
      fatalError()
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
