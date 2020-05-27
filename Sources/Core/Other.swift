internal func bin(_ value: Int32) -> String {
  return bin(UInt32(bitPattern: value))
}

internal func bin(_ value: UInt32) -> String {
  return String(value, radix: 2, uppercase: false)
}

internal func bin(_ value: Int) -> String {
  return bin(UInt(bitPattern: value))
}

internal func bin(_ value: UInt) -> String {
  return String(value, radix: 2, uppercase: false)
}

// swiftlint:disable:next unavailable_function
public func trap(_ msg: String,
                 file: StaticString = #file,
                 function: StaticString = #function,
                 line: Int = #line) -> Never {
  fatalError("\(file):\(line) - \(msg)")
}

extension BinaryInteger {

  internal var isZero: Bool {
    return self == .zero
  }

  internal var isPositive: Bool {
    return self > .zero
  }

  internal var isNegative: Bool {
    return self < .zero
  }
}

extension FixedWidthInteger {

  /// Number of bits necessary to represent self in binary.
  /// `bitLength` in Python.
  internal var minRequiredWidth: Int {
    if self >= .zero {
      return self.bitWidth - self.leadingZeroBitCount
    }

    let sign = 1
    let inverted = ~self
    return self.bitWidth - inverted.leadingZeroBitCount + sign
  }

  internal typealias FullWidthAdd = (carry: Self, result: Self)

  /// `result = self + y`
  internal func addingFullWidth(_ y: Self) -> FullWidthAdd {
    let (result, overflow) = self.addingReportingOverflow(y)
    let carry: Self = overflow ? 1 : 0
    return (carry, result)
  }

  /// `result = self + y + z`
  internal func addingFullWidth(_ y: Self, _ z: Self) -> FullWidthAdd {
    let (xy, overflow1) = self.addingReportingOverflow(y)
    let (xyz, overflow2) = xy.addingReportingOverflow(z)
    let carry: Self = (overflow1 ? 1 : 0) + (overflow2 ? 1 : 0)
    return (carry, xyz)
  }

  internal typealias FullWidthSub = (borrow: Self, result: Self)

  /// `result = self - y`
  internal func subtractingFullWidth(_ y: Self) -> FullWidthSub {
    let (result, overflow) = self.subtractingReportingOverflow(y)
    let borrow: Self = overflow ? 1 : 0
    return (borrow, result)
  }

  /// `result = self - y - z`
  internal func subtractingFullWidth(_ y: Self, _ z: Self) -> FullWidthSub {
    let (xy, overflow1) = self.subtractingReportingOverflow(y)
    let (xyz, overflow2) = xy.subtractingReportingOverflow(z)
    let borrow: Self = (overflow1 ? 1 : 0) + (overflow2 ? 1 : 0)
    return (borrow, xyz)
  }
}
