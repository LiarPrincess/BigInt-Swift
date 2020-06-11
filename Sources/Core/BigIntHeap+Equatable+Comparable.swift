extension BigIntHeap {

  // MARK: - Hashable

  internal func hash(into hasher: inout Hasher) {
    if let smi = self.asSmiIfPossible() {
      smi.hash(into: &hasher)
    } else {
      hasher.combine(self.isNegative)
      hasher.combine(self.storage.count)

      for word in self.storage {
        hasher.combine(word)
      }
    }
  }

  // MARK: - Equatable

  internal static func == (heap: BigIntHeap, smi: Smi.Storage) -> Bool {
    // Different signs are never equal
    guard heap.isNegative == smi.isNegative else {
      return false
    }

    // If we have more than 1 word then we are out of range of smi
    if heap.storage.count > 1 {
      return false
    }

    // We have the same sign. Do we have the same magnitude?
    // If we do not have any words then we are '0'
    let heapMagnitude = heap.storage.first ?? 0
    let smiMagnitude = smi.magnitude
    return heapMagnitude == smiMagnitude
  }

  internal static func == (lhs: BigIntHeap, rhs: BigIntHeap) -> Bool {
    return lhs.storage == rhs.storage
  }

  // MARK: - Comparable

  internal static func < (heap: BigIntHeap, smi: Smi.Storage) -> Bool {
    // Negative values are always smaller than positive ones (because math...)
    guard heap.isNegative == smi.isNegative else {
      return heap.isNegative
    }

    // If we have more than 1 word then we are out of range of smi
    if heap.storage.count > 1 {
      // We have the same sign:
      // - if we are 'positive' then more words -> greater number
      // - if we are 'negative' then more words -> smaller number
      return heap.isNegative
    }

    // If we do not have any words then we are '0'
    let heapMagnitude = heap.storage.first ?? 0
    let smiMagnitude = smi.magnitude

    // We have the same sign:
    // - if we are 'positive' then bigger magnitude -> greater number
    // - if we are 'negative' then bigger magnitude -> smaller number
    return smi.isPositive ?
      heapMagnitude < smiMagnitude :
      heapMagnitude > smiMagnitude
  }

  internal static func < (lhs: BigIntHeap, rhs: BigIntHeap) -> Bool {
    // Negative values are always smaller than positive ones (because math...)
    guard lhs.isNegative == rhs.isNegative else {
      return lhs.isNegative
    }

    // Shorter number is always smaller
    guard lhs.storage.count == rhs.storage.count else {
      return lhs.storage.count < rhs.storage.count
    }

    // Compare from most significant word
    for (lhsWord, rhsWord) in zip(lhs.storage, rhs.storage).reversed() {
      if lhsWord < rhsWord {
        return true
      }

      if lhsWord > rhsWord {
        return false
      }

      // Equal -> compare next word
    }

    // Numbers are equal
    return false
  }

  // MARK: - Compare magnitudes

  internal enum CompareResult {
    case equal
    case less
    case greater
  }

  internal func compareMagnitude(with other: Word) -> CompareResult {
    // If we have more than 1 word then we are out of range of 'Word'
    if self.storage.count > 1 {
      return .greater
    }

    // If we do not have any words then we are '0'
    let selfWord = self.storage.first ?? 0
    return selfWord == other ? .equal :
           selfWord > other ? .greater :
          .less
  }

  internal func compareMagnitude(with other: BigIntHeap) -> CompareResult {
    return self.compareMagnitude(with: other.storage)
  }

  internal func compareMagnitude(with other: BigIntStorage) -> CompareResult {
    // Shorter number is always smaller
    guard self.storage.count == other.count else {
      return self.storage.count < other.count ? .less : .greater
    }

    // Compare from most significant word
    for (selfWord, otherWord) in zip(self.storage, other).reversed() {
      if selfWord < otherWord {
        return .less
      }

      if selfWord > otherWord {
        return .greater
      }

      // Equal -> compare next word
    }

    return .equal
  }
}
