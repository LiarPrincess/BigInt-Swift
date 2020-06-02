extension BigIntHeap {

  // MARK: - Equatable

  internal static func == (heap: BigIntHeap, smi: Smi) -> Bool {
    // Different signs are never equal
    guard heap.isNegative == smi.isNegative else {
      return false
    }

    let lhs = heap.storage
    let rhs = Word(smi.value.magnitude)
    switch Self.compareMagnitudes(lhs: lhs, rhs: rhs) {
    case .equal:
      return true
    case .less,
         .greater:
      return false
    }
  }

  internal static func == (lhs: BigIntHeap, rhs: BigIntHeap) -> Bool {
    return lhs.storage == rhs.storage
  }

  // MARK: - Comparable

  internal static func >= (heap: BigIntHeap, smi: Smi) -> Bool {
    // Negative values are always smaller than positive ones (because math...)
    guard heap.isNegative == smi.isNegative else {
      return smi.isNegative
    }

    let lhs = heap.storage
    let rhs = Word(smi.value.magnitude)
    switch Self.compareMagnitudes(lhs: lhs, rhs: rhs) {
    case .equal,
         .greater:
      return true
    case .less:
      return false
    }
  }

  internal static func < (heap: BigIntHeap, smi: Smi) -> Bool {
    // Negative values are always smaller than positive ones (because math...)
    guard heap.isNegative == smi.isNegative else {
      return heap.isNegative
    }

    let lhs = heap.storage
    let rhs = Word(smi.value.magnitude)
    switch Self.compareMagnitudes(lhs: lhs, rhs: rhs) {
    case .less:
      return true
    case .equal,
         .greater:
      return false
    }
  }

  internal static func < (lhs: BigIntHeap, rhs: BigIntHeap) -> Bool {
    // Negative values are always smaller than positive ones (because math...)
    guard lhs.isNegative == rhs.isNegative else {
      return lhs.isNegative
    }

    switch Self.compareMagnitudes(lhs: lhs.storage, rhs: rhs.storage) {
    case .less:
      return true
    case .equal,
         .greater:
      return false
    }
  }

  // MARK: - Compare magnitudes

  internal enum CompareMagnitudes {
    case equal
    case less
    case greater
  }

  internal static func compareMagnitudes(lhs: BigIntStorage,
                                         rhs: Word) -> CompareMagnitudes {
    // If we have more words than 1 then we are our of range of smi
    if lhs.count > 1 {
      return .greater
    }

    // We have only 1 word in heap -> compare with value
    let lhsWord = lhs[0]
    let rhsWord = Word(rhs.magnitude)
    return lhsWord == rhsWord ? .equal :
           lhsWord > rhsWord ? .greater :
          .less
  }

  internal static func compareMagnitudes(lhs: BigIntStorage,
                                         rhs: BigIntStorage) -> CompareMagnitudes {
    // Shorter number is always smaller
    guard lhs.count == rhs.count else {
      return lhs.count < rhs.count ? .less : .greater
    }

    // Compare from most significant word
    for (lhsWord, rhsWord) in zip(lhs, rhs).reversed() {
      if lhsWord < rhsWord {
        return .less
      }

      if lhsWord > rhsWord {
        return .greater
      }

      // Equal -> compare next word
    }

    return .equal
  }
}
