import BigIntProxy

/// This wrapper around `BigIntProxy`.
///
/// If we ever decide to change our `BigInt` library this is the class to change.
///
/// Btw. It has `reference` semantics, so be carefull!
/// Use `copy()` if needed.
internal final class BigIntHeap: CustomStringConvertible, CustomDebugStringConvertible {

  // MARK: - Properties

  private var value: BigIntProxy

  internal var magnitude: BigInt {
    let result = self.value.magnitude
    let resultHeap = BigIntHeap(value: result)
    return BigInt(resultHeap)
  }

  // MARK: - Init

  internal init(value: BigIntProxy) {
    self.value = value
  }

  internal init<T: BinaryInteger>(_ value: T) {
    self.value = BigIntProxy(value)
  }

  // MARK: - Negate

  internal func negate() {
    self.value.negate()
  }

  // MARK: - Invert

  internal func invert() {
    self.value = ~self.value
  }

  // MARK: - Add

  internal func add(other: Smi) {
    let big = BigIntProxy(other.value)
    self.value += big
  }

  internal func add(other: BigIntHeap) {
    self.value += other.value
  }

  // MARK: - Sub

  internal func sub(other: Smi) {
    let big = BigIntProxy(other.value)
    self.value -= big
  }

  internal func sub(other: BigIntHeap) {
    self.value -= other.value
  }

  // MARK: - Mul

  internal func mul(other: Smi) {
    let big = BigIntProxy(other.value)
    self.value *= big
  }

  internal func mul(other: BigIntHeap) {
    self.value *= other.value
  }

  // MARK: - Div

  internal func div(other: Smi) {
    let big = BigIntProxy(other.value)
    self.value /= big
  }

  internal func div(other: BigIntHeap) {
    self.value /= other.value
  }

  // MARK: - Mod

  internal func mod(other: Smi) {
    let big = BigIntProxy(other.value)
    self.value %= big
  }

  internal func mod(other: BigIntHeap) {
    self.value %= other.value
  }

  // MARK: - Div mod

  internal typealias DivMod = (quotient: BigIntHeap, remainder: BigIntHeap)

  internal static func divMod(lhs: BigIntHeap, rhs: BigIntHeap) -> DivMod {
    let result = lhs.value.quotientAndRemainder(dividingBy: rhs.value)
    let quotient = BigIntHeap(value: result.quotient)
    let remainder = BigIntHeap(value: result.remainder)
    return (quotient: quotient, remainder: remainder)
  }

  // MARK: - Shift left

  internal func shiftLeft<T: BinaryInteger>(count: T) {
    self.value <<= count
  }

  // MARK: - Shift right

  internal func shiftRight<T: BinaryInteger>(count: T) {
    self.value >>= count
  }

  // MARK: - String

  internal var description: String {
    return String(describing: self.value)
  }

  internal var debugDescription: String {
    let value = String(describing: self.value)
    return "BigIntHeap(\(value))"
  }

  internal func toString(radix: Int, uppercase: Bool) -> String {
    return String(self.value, radix: radix, uppercase: uppercase)
  }

  // MARK: - Equatable

  internal static func == (lhs: BigIntHeap, rhs: Smi) -> Bool {
    return lhs.value == rhs.value
  }

  internal static func == (lhs: BigIntHeap, rhs: BigIntHeap) -> Bool {
    return lhs.value == rhs.value
  }

  // MARK: - Comparable

  internal static func < (lhs: BigIntHeap, rhs: Smi) -> Bool {
    return lhs.value < rhs.value
  }

  internal static func < (lhs: BigIntHeap, rhs: BigIntHeap) -> Bool {
    return lhs.value < rhs.value
  }

  internal static func >= (lhs: BigIntHeap, rhs: Smi) -> Bool {
    return lhs.value >= rhs.value
  }

  // MARK: - Hashable

  internal func hash(into hasher: inout Hasher) {
    if let smi = self.asSmiIfPossible() {
      smi.hash(into: &hasher)
    } else {
      self.value.hash(into: &hasher)
    }
  }

  // MARK: - Copy

  internal func copy() -> BigIntHeap {
    return BigIntHeap(value: self.value)
  }

  // MARK: - Type conversion

  internal func asSmiIfPossible() -> Smi? {
    if let smi = Smi(self.value) {
      return smi
    }

    return nil
  }
}
