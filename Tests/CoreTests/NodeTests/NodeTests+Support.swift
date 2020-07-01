import XCTest
import Core

// swiftlint:disable function_parameter_count

// Basically all of the code that does not need to be regenerated by Node.
extension NodeTests {

  // MARK: - Binary operations

  internal func addTest(lhs: String,
                        rhs: String,
                        expecting: String,
                        file: StaticString = #file,
                        line: UInt = #line) {
    self.binaryOp(
      lhs: lhs,
      rhs: rhs,
      expecting: expecting,
      op: { $0 + $1 },
      inoutOp: { $0 += $1 },
      file: file,
      line: line
    )
  }

  internal func subTest(lhs: String,
                        rhs: String,
                        expecting: String,
                        file: StaticString = #file,
                        line: UInt = #line) {
    self.binaryOp(
      lhs: lhs,
      rhs: rhs,
      expecting: expecting,
      op: { $0 - $1 },
      inoutOp: { $0 -= $1 },
      file: file,
      line: line
    )
  }

  internal func mulTest(lhs: String,
                        rhs: String,
                        expecting: String,
                        file: StaticString = #file,
                        line: UInt = #line) {
    self.binaryOp(
      lhs: lhs,
      rhs: rhs,
      expecting: expecting,
      op: { $0 * $1 },
      inoutOp: { $0 *= $1 },
      file: file,
      line: line
    )
  }

  internal func divTest(lhs: String,
                        rhs: String,
                        expecting: String,
                        file: StaticString = #file,
                        line: UInt = #line) {
    self.binaryOp(
      lhs: lhs,
      rhs: rhs,
      expecting: expecting,
      op: { $0 / $1 },
      inoutOp: { $0 /= $1 },
      file: file,
      line: line
    )
  }

  internal func modTest(lhs: String,
                        rhs: String,
                        expecting: String,
                        file: StaticString = #file,
                        line: UInt = #line) {
    self.binaryOp(
      lhs: lhs,
      rhs: rhs,
      expecting: expecting,
      op: { $0 % $1 },
      inoutOp: { $0 %= $1 },
      file: file,
      line: line
    )
  }

  internal func andTest(lhs: String,
                        rhs: String,
                        expecting: String,
                        file: StaticString = #file,
                        line: UInt = #line) {
    self.binaryOp(
      lhs: lhs,
      rhs: rhs,
      expecting: expecting,
      op: { $0 & $1 },
      inoutOp: { $0 &= $1 },
      file: file,
      line: line
    )
  }

  internal func orTest(lhs: String,
                       rhs: String,
                       expecting: String,
                       file: StaticString = #file,
                       line: UInt = #line) {
    self.binaryOp(
      lhs: lhs,
      rhs: rhs,
      expecting: expecting,
      op: { $0 | $1 },
      inoutOp: { $0 |= $1 },
      file: file,
      line: line
    )
  }

  internal func xorTest(lhs: String,
                        rhs: String,
                        expecting: String,
                        file: StaticString = #file,
                        line: UInt = #line) {
    self.binaryOp(
      lhs: lhs,
      rhs: rhs,
      expecting: expecting,
      op: { $0 ^ $1 },
      inoutOp: { $0 ^= $1 },
      file: file,
      line: line
    )
  }

  internal typealias BinaryOperation = (BigInt, BigInt) -> BigInt
  internal typealias InoutBinaryOperation = (inout BigInt, BigInt) -> Void

  private func binaryOp(lhs lhsString: String,
                        rhs rhsString: String,
                        expecting expectedString: String,
                        op: BinaryOperation,
                        inoutOp: InoutBinaryOperation,
                        file: StaticString,
                        line: UInt) {
    let lhs: BigInt
    let lhsBeforeInout: BigInt // Later to check if 'inout' did not modify orginal
    do {
      lhs = try self.create(string: lhsString, radix: 10)
      lhsBeforeInout = try self.create(string: lhsString, radix: 10)
    } catch {
      XCTFail("Unable to parse lhs: \(error)", file: file, line: line)
      return
    }

    let rhs: BigInt
    do {
      rhs = try self.create(string: rhsString, radix: 10)
    } catch {
      XCTFail("Unable to parse rhs: \(error)", file: file, line: line)
      return
    }

    let expected: BigInt
    do {
      expected = try self.create(string: expectedString, radix: 10)
    } catch {
      XCTFail("Unable to parse expected: \(error)", file: file, line: line)
      return
    }

    // Check 'standard' op
    let result = op(lhs, rhs)
    XCTAssertEqual(result, expected, file: file, line: line)

    // Check 'inout' op
    var inoutLhs = lhs
    inoutOp(&inoutLhs, rhs)
    XCTAssertEqual(inoutLhs, expected, "INOUT!!1", file: file, line: line)

    // Make sure that 'inout' did not modify orginal
    XCTAssertEqual(lhs, lhsBeforeInout, "Inout did modify orginal value", file: file, line: line)
  }

  /// Abstraction over `BigInt.init(_:radix:)`.
  private func create(string: String, radix: Int) throws -> BigInt {
    return try BigInt(string, radix: radix)
  }
}
