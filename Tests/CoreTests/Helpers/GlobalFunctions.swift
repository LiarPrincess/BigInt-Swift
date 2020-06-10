// MARK: - Pair values

internal struct PossiblePairings<T>: Sequence {

  internal typealias Element = (T, T)

  internal struct Iterator: IteratorProtocol {
    private var lhsIndex = 0
    private var rhsIndex = 0
    private let values: [T]

    fileprivate init(values: [T]) {
      self.values = values
    }

    internal mutating func next() -> Element? {
      if self.lhsIndex == self.values.count {
        return nil
      }

      let lhs = self.values[self.lhsIndex]
      let rhs = self.values[self.rhsIndex]

      self.rhsIndex += 1
      if self.rhsIndex == self.values.count {
        self.lhsIndex += 1
        self.rhsIndex = 0
      }

      return (lhs, rhs)
    }
  }

  private let values: [T]

  fileprivate init(values: [T]) {
    self.values = values
  }

  internal func makeIterator() -> Iterator {
    return Iterator(values: self.values)
  }
}

/// `[1, 2] -> [(1,1), (1,2), (2,1), (2,2)]`
internal func allPossiblePairings<T>(values: [T]) -> PossiblePairings<T> {
  return PossiblePairings(values: values)
}

// MARK: - Powers of 2

internal typealias PowerOf2<T> = (power: Int, value: T)

/// `1, 2, 4, 8, 16, 32, 64, 128, 256, 512, etc...`
internal func allPositivePowersOf2<T: FixedWidthInteger & BinaryInteger>(
  type: T.Type
) -> [PowerOf2<T>] {
  var result = [PowerOf2<T>]()
  result.reserveCapacity(T.bitWidth)

  for shift in 0..<(T.bitWidth - 1) {
    let value = T(1 << shift)
    result.append(PowerOf2(power: shift, value: value))
  }

  return result
}

/// `-1, -2, -4, -8, -16, -32, -64, -128, -256, -512, etc...`
internal func allNegativePowersOf2<T: FixedWidthInteger & BinaryInteger>(
  type: T.Type
) -> [PowerOf2<T>] {
  var result = [PowerOf2<T>]()
  result.reserveCapacity(T.bitWidth)

  for shift in 0..<T.bitWidth {
    let int = -(1 << shift)
    let value = T(int)
    result.append(PowerOf2(power: shift, value: value))
  }

  return result
}
