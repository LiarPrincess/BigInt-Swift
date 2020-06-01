import BigIntProxy

/// This wrapper around `BigIntProxy`.
///
/// If we ever decide to change our `BigInt` library this is the class to change.
///
/// Btw. It has `reference` semantics, so be carefull!
/// Use `copy()` if needed.
internal final class BigIntHeapOld: CustomStringConvertible, CustomDebugStringConvertible {

  internal typealias Words = BigIntProxy.Words

  // MARK: - Properties

  private var value: BigIntProxy

  internal var words: Words {
    return self.value.words
  }

  internal var bitWidth: Int {
    return self.value.bitWidth
  }

  internal var trailingZeroBitCount: Int {
    return self.value.trailingZeroBitCount
  }

  internal var minRequiredWidth: Int {
    // Important:
    // This depends on the 'BigInt' library that we are using!
    return self.value.bitWidth
  }

  internal var magnitude: BigInt {
    let result = self.value.magnitude
    let resultHeap = BigIntHeapOld(value: result)
    return BigInt(resultHeap)
  }

  // MARK: - Init

  internal init(value: BigIntProxy) {
    self.value = value
  }

  internal init(value: BigIntProxy.Magnitude) {
    self.value = BigIntProxy(sign: .plus, magnitude: value)
  }

  internal init<T: BinaryInteger>(_ value: T) {
    self.value = BigIntProxy(value)
  }

  internal init<T: BinaryFloatingPoint>(_ source: T) {
    self.value = BigIntProxy(source)
  }

  internal init?<T: BinaryFloatingPoint>(exactly source: T) {
    guard let value = BigIntProxy(exactly: source) else {
      return nil
    }

    self.value = value
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

  internal func add(other: BigIntHeapOld) {
    self.value += other.value
  }

  // MARK: - Sub

  internal func sub(other: Smi) {
    let big = BigIntProxy(other.value)
    self.value -= big
  }

  internal func sub(other: BigIntHeapOld) {
    self.value -= other.value
  }

  // MARK: - Mul

  internal func mul(other: Smi) {
    let big = BigIntProxy(other.value)
    self.value *= big
  }

  internal func mul(other: BigIntHeapOld) {
    self.value *= other.value
  }

  // MARK: - Div

  internal func div(other: Smi) {
    let big = BigIntProxy(other.value)
    self.value /= big
  }

  internal func div(other: BigIntHeapOld) {
    self.value /= other.value
  }

  // MARK: - Mod

  internal func mod(other: Smi) {
    let big = BigIntProxy(other.value)
    self.value %= big
  }

  internal func mod(other: BigIntHeapOld) {
    self.value %= other.value
  }

  // MARK: - Div mod

  internal typealias DivMod = (quotient: BigIntHeapOld, remainder: BigIntHeapOld)

  internal static func divMod(lhs: BigIntHeapOld, rhs: BigIntHeapOld) -> DivMod {
    let result = lhs.value.quotientAndRemainder(dividingBy: rhs.value)
    let quotient = BigIntHeapOld(value: result.quotient)
    let remainder = BigIntHeapOld(value: result.remainder)
    return (quotient: quotient, remainder: remainder)
  }

  // MARK: - And

  internal func and(other: Smi) {
    let big = BigIntProxy(other.value)
    self.value &= big
  }

  internal func and(other: BigIntHeapOld) {
    self.value &= other.value
  }

  // MARK: - Or

  internal func or(other: Smi) {
    let big = BigIntProxy(other.value)
    self.value |= big
  }

  internal func or(other: BigIntHeapOld) {
    self.value |= other.value
  }

  // MARK: - Xor

  internal func xor(other: Smi) {
    let big = BigIntProxy(other.value)
    self.value ^= big
  }

  internal func xor(other: BigIntHeapOld) {
    self.value ^= other.value
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

  internal static func == (lhs: BigIntHeapOld, rhs: Smi) -> Bool {
    return lhs.value == rhs.value
  }

  internal static func == (lhs: BigIntHeapOld, rhs: BigIntHeapOld) -> Bool {
    return lhs.value == rhs.value
  }

  // MARK: - Comparable

  internal static func < (lhs: BigIntHeapOld, rhs: Smi) -> Bool {
    return lhs.value < rhs.value
  }

  internal static func < (lhs: BigIntHeapOld, rhs: BigIntHeapOld) -> Bool {
    return lhs.value < rhs.value
  }

  internal static func >= (lhs: BigIntHeapOld, rhs: Smi) -> Bool {
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

  internal func copy() -> BigIntHeapOld {
    return BigIntHeapOld(value: self.value)
  }

  // MARK: - Type conversion

  internal func asSmiIfPossible() -> Smi? {
    if let smi = Smi(self.value) {
      return smi
    }

    return nil
  }
}