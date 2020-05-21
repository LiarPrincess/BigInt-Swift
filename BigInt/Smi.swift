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
    return self.value == .zero
  }

  internal var isNegative: Bool {
    return self.value < Storage(0)
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

  // MARK: - Binary operators

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

  private func twoComplement(value: Storage) -> Storage {
    return (~value) &+ 1
  }
/*
  internal func sub(other: Smi) -> BigInt {
    let result = self.value.subtractingReportingOverflow(other.value)
    if !result.overflow {
      return BigInt(Smi(result.partialValue))
    }

    // Zero - (-max)
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

  internal func toString(radix: Int, uppercase: Bool) -> String {
    return String(self.value, radix: radix, uppercase: uppercase)
  }

  // MARK: - Comparable

  internal static func < (lhs: Smi, rhs: Smi) -> Bool {
    return lhs.value < rhs.value
  }
}
