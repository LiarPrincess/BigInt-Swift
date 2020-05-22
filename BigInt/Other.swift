internal func bin(_ value: Int32) -> String {
  return bin(UInt32(bitPattern: value))
}

internal func bin(_ value: UInt32) -> String {
  return String(value, radix: 2, uppercase: false)
}

// swiftlint:disable:next unavailable_function
public func trap(_ msg: String,
                 file: StaticString = #file,
                 function: StaticString = #function,
                 line: Int = #line) -> Never {
  fatalError("\(file):\(line) - \(msg)")
}

extension FixedWidthInteger {

  /// Returns the high and low parts of a potentially overflowing addition.
  fileprivate func addingFullWidth(_ other: Self) -> (high: Self, low: Self) {
    let sum = self.addingReportingOverflow(other)
    return (sum.overflow ? 1 : 0, sum.partialValue)
  }

  /// Returns a tuple containing the value that would be borrowed from a higher
  /// place and the partial difference of this value and `rhs`.
  fileprivate func subtractingWithBorrow(_ other: Self) ->
    (borrow: Self, partialValue: Self) {
    let difference = subtractingReportingOverflow(other)
    return (difference.overflow ? 1 : 0, difference.partialValue)
  }
}
