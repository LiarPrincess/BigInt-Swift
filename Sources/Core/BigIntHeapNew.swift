internal struct BigIntNew {

  internal enum Storage {
    case smi(Smi)
    case heap(BigIntHeapNew)
  }

  internal private(set) var value: Storage

  /// This will downgrade to `Smi` if possible
  internal init(_ value: BigIntHeapNew) {
    self.value = .heap(value)
  }
}

internal struct BigIntHeapNew {

  internal typealias Word = BigIntStorage.Word

  // MARK: - Properties

  /// The binary representation of the value's magnitude,
  /// with the least significant word at index `0`.
  ///
  /// - `data` has no trailing zero elements
  /// - If `self == 0`, then `isNegative == false` and `data == []`
  private var storage: BigIntStorage

  private var isZero: Bool {
    return self.storage.isZero
  }

  /// `0` is also positive.
  private var isPositive: Bool {
    return !self.isNegative
  }

  private var isNegative: Bool {
    return self.storage.isNegative
  }

  private var count: Int {
    return self.storage.count
  }

  internal var words: BigIntStorage {
    // We will return 'BigIntStorage' to save allocation in some cases.
    // But remember that in this case it will be used as collection,
    // that means that eny additional data (sign etc.) will be ignored.

    if self.isZero {
      return self.storage
    }

    if self.isPositive {
      // If we start with '1' then we have to add artificial '0' in front.
      // This does not happen very often.
      if let last = self.storage.last, last >> (Word.bitWidth - 1) == 1 {
        var copy = self.storage
        let token = copy.guaranteeUniqueBufferReference()
        copy.append(0, token: token)
        return copy
      }

      return self.storage
    }

    assert(self.isNegative)

    // At this point our 'storage' holds positive number, so we have 2 complement it.
    var copy = self.storage
    let token = copy.guaranteeUniqueBufferReference()
    copy.map(fn: ~, token: token)
    copy.addMagnitude(other: 1, token: token)
    return copy
  }

  /// The minimum number of bits required to represent this integer in binary.
  internal var bitWidth: Int {
    guard let last = self.storage.last else {
      assert(self.isZero)
      return 0
    }

    let sign = 1
    return self.count * Word.bitWidth - last.leadingZeroBitCount + sign
  }

  /// The number of trailing zero bits in the binary representation of this integer.
  ///
  /// - Important:
  /// `0` is considered to have zero trailing zero bits.
  internal var trailingZeroBitCount: Int {
    if let index = self.storage.lastIndex(where: { $0 != 0 }) {
      let word = self.storage[index]
      return index * Word.bitWidth + word.trailingZeroBitCount
    }

    assert(self.isZero)
    return 0
  }

  internal var minRequiredWidth: Int {
    return self.bitWidth
  }

  internal var magnitude: BigIntNew {
    if self.isPositive {
      return BigIntNew(self)
    }

    var abs = self
    abs.negate()
    assert(abs.isPositive)
    return abs.magnitude
  }

  // MARK: - Init
  /*

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
 */

  // MARK: - Unary

  /// void
  /// mpz_neg (mpz_t r, const mpz_t u)
  internal mutating func negate() {
    // Zero is always positive
    if self.isZero {
      assert(self.isPositive)
      return
    }

    let token = self.storage.guaranteeUniqueBufferReference()
    self.storage.toggleIsNegative(token: token)
    self.storage.checkInvariants()
  }

  /// void
  /// mpz_com (mpz_t r, const mpz_t u)
  internal mutating func invert() {
    self.add(other: 1)
    self.negate()
  }

  // MARK: - Add

  private mutating func add(other: Smi.Storage) { }
}
