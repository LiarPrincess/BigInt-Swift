internal struct BigIntHeap: Equatable, Hashable {

  internal typealias Word = BigIntStorage.Word

  // MARK: - Properties

  internal var storage: BigIntStorage

  internal var isZero: Bool {
    return self.storage.isZero
  }

  /// `0` is also positive.
  internal var isPositive: Bool {
    return self.storage.isPositive
  }

  internal var isNegative: Bool {
    return self.storage.isNegative
  }

  /// DO NOT USE in general code! This will do allocation!
  ///
  /// This is not one of those 'easy/fast' methods.
  /// It is only here for `BigInt.magnitude`.
  internal var magnitude: BigInt {
    if self.isPositive {
      return BigInt(self)
    }

    var abs = self
    abs.negate()
    abs.checkInvariants()
    assert(abs.isPositive)
    return BigInt(abs)
  }

  internal var hasMagnitudeOfOne: Bool {
    return self.storage.count == 1 && self.storage[0] == 1
  }

  // MARK: - Init

  /// Init with storage set to `0`.
  internal init() {
    self.storage = .zero
  }

  // TODO: Remove this
  internal init(minimumStorageCapacity: Int) {
    self.storage = BigIntStorage(minimumCapacity: minimumStorageCapacity)
  }

  internal init<T: BinaryInteger>(_ value: T) {
    // Assuming that biggest 'BinaryInteger' in Swift is representable by 'Word'.
    let isNegative = value.isNegative
    let magnitude = Word(value.magnitude)
    self.storage = BigIntStorage(isNegative: isNegative, magnitude: magnitude)
  }

  internal init(storage: BigIntStorage) {
    self.storage = storage
    self.fixInvariants()
  }

  // MARK: - Invariants

  internal mutating func fixInvariants() {
    self.storage.fixInvariants()
  }

  internal func checkInvariants() {
    self.storage.checkInvariants()
  }

  // MARK: - Set

  internal mutating func setToZero() {
    self.storage = BigIntStorage.zero
    assert(self.isPositive)
  }

  /// Set `self` to represent given `Word`.
  internal mutating func set(to value: Word) {
    // We do not have to call 'self.guaranteeUniqueBufferReference'
    // because all of the functions we are using will do it anyway.

    if value == 0 {
      self.setToZero()
    } else {
      self.storage.removeAll()
      self.storage.isNegative = false
      self.storage.append(value)
    }
  }

  /// Set `self` to represent given `Int`.
  internal mutating func set(to value: Int) {
    // We do not have to call 'self.guaranteeUniqueBufferReference'
    // because all of the functions we are using will do it anyway.

    if value == 0 {
      self.setToZero()
    } else {
      self.storage.removeAll()
      self.storage.isNegative = value.isNegative
      self.storage.append(value.magnitude)
    }
  }

  // MARK: - Type conversion

  internal func asSmiIfPossible() -> Smi? {
    if self.isZero {
      return Smi(Smi.Storage.zero)
    }

    // If we have more than 1 word then we are out of range
    guard self.storage.count == 1 else {
      return nil
    }

    let word = self.storage[0]
    if let storage = word.asSmiIfPossible(isNegative: self.isNegative) {
      return Smi(storage)
    }

    return nil
  }
}
