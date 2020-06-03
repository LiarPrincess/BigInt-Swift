internal struct BigIntNew {

  internal enum Storage {
    case smi(Smi)
    case heap(BigIntHeap)
  }

  internal private(set) var value: Storage

  /// This will downgrade to `Smi` if possible
  internal init(_ value: BigIntHeap) {
    self.value = .heap(value)
  }
}

internal struct BigIntHeap: Equatable {

  internal typealias Word = BigIntStorage.Word

  // MARK: - Properties

  internal var storage: BigIntStorage

  internal var isZero: Bool {
    return self.storage.isZero
  }

  /// `0` is also positive.
  internal var isPositive: Bool {
    return !self.isNegative
  }

  internal var isNegative: Bool {
    return self.storage.isNegative
  }

  internal var magnitude: BigIntNew {
    if self.isPositive {
      return BigIntNew(self)
    }

    var abs = self
    abs.negate()
    abs.checkInvariants()
    assert(abs.isPositive)
    return BigIntNew(abs)
  }

  internal var hasMagnitudeOfOne: Bool {
    return self.storage.count == 1 && self.storage[0] == 1
  }

  // MARK: - Init

  /// Init with storage set to `0`.
  internal init() {
    self.storage = BigIntStorage(minimumCapacity: 0)
  }

  internal init(minimumStorageCapacity: Int) {
    self.storage = BigIntStorage(minimumCapacity: minimumStorageCapacity)
  }

  internal init<T: BinaryInteger>(_ value: T) {
    // Assuming that biggest 'BinaryInteger' in Swift is representable by 'Word'.
    let magnitude = Word(value.magnitude)
    self.storage = BigIntStorage(value: magnitude)

    if value.isNegative {
      self.storage.isNegative = true
    }

    self.checkInvariants()
  }

  // MARK: - Unary

  internal mutating func negate() {
    // Zero is always positive
    if self.isZero {
      assert(self.isPositive)
      return
    }

    self.storage.isNegative.toggle()
    self.checkInvariants()
  }

  internal mutating func invert() {
    self.add(other: 1)
    self.negate()
    self.checkInvariants()
  }

  // MARK: - Invariants

  internal mutating func fixInvariants() {
    self.storage.fixInvariants()
  }

  internal func checkInvariants() {
    self.storage.checkInvariants()
  }

  // MARK: - Type conversion

  internal func asSmiIfPossible() -> Smi? {
    guard self.storage.count == 1 else {
      return nil
    }

    let word = self.storage[0]
    if self.isPositive {
      return Smi(word)
    }

    let max = Word(Smi.Storage.min.magnitude)
    if word > max {
      return nil
    }

    // We are in a 'Smi.Storage' range, which also means that we are in 'Int' range
    let signed = -Int(word)
    return Smi(signed)
  }
}
