@testable import Core

// MARK: - BigInt

extension BigInt {

  internal var isSmi: Bool {
    switch self.value {
    case .smi: return true
    case .heap: return false
    }
  }

  internal var isHeap: Bool {
    return !self.isSmi
  }
}

// MARK: - Pair values

internal func allPossiblePairings<T>(values: [T]) -> [(T, T)] {
  var result = [(T, T)]()
  result.reserveCapacity(values.count * values.count)

  for lhs in values {
    for rhs in values {
      let pair = (lhs, rhs)
      result.append(pair)
    }
  }

  return result
}

// MARK: - Powers of 2

internal typealias PowerOf2<T> = (power: Int, value: T)

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
