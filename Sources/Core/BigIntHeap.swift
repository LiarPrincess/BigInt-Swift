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