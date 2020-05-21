/// Small integer, named after similiar type in `V8`.
internal struct Smi: Comparable, CustomStringConvertible, CustomDebugStringConvertible {

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
    return self.value == 0
  }

  internal var isNegative: Bool {
    return self.value < 0
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

  // MARK: - Unary operators

  internal var minus: BigInt {
    // Binary numbers have a bit bigger range on the negative side
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

  // MARK: - Binary operators
/*
  internal func add(other: Smi) -> BigInt {
    let result = self.value.addingReportingOverflow(other.value)
    if !result.overflow {
      return BigInt(Smi(result.partialValue))
    }

    // It is either:
    // - 2 positive numbers added together
    // - 2 negative numbers added together

    let unsignedPartialValue = UInt32(result.partialValue)
    let heap = BigIntHeap(low: unsignedPartialValue, high: 1)
    return BigInt(heap)
  }

  internal func sub(other: Smi) -> BigInt {
    let result = self.value.subtractingReportingOverflow(other.value)
    if !result.overflow {
      return BigInt(Smi(result.partialValue))
    }

    fatalError()
  }


//  internal func mul(other: SmallInt) -> NBigInt {
//    let result = self.value.multipliedFullWidth(by: other.value)
//    if result.high == 0 {
//      let sign = result.high.s
//      return NBigInt(diff.partialValue)
//    }
//
//    fatalError()
//  }
*/

  // MARK: - String

  internal var description: String {
    return self.value.description
  }

  internal var debugDescription: String {
    return "Smi(\(self.value))"
  }

  // 'toString' because we Java now
  internal func toString(radix: Int, uppercase: Bool) -> String {
    precondition(2 <= radix && radix <= 36, "radix must be in range 2...36")
    return String(self.value, radix: radix, uppercase: uppercase)
  }

  // MARK: - Comparable

  internal static func < (lhs: Smi, rhs: Smi) -> Bool {
    return lhs.value < rhs.value
  }
}
