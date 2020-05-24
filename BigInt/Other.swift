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
