import XCTest
@testable import Core

class BigIntStringInitTests: XCTestCase {

  // MARK: - Empty

  func test_empty_throws() {
    for radix in [2, 4, 7, 32] {
      do {
        _ = try self.create(string: "", radix: radix)
        XCTFail("No error")
      } catch BigInt.ParsingError.emptyString {
        // Expected
      } catch {
        XCTFail("Error: \(error), radix: \(radix)")
      }
    }
  }

  // MARK: - Smi

  func test_smi_decimal() {
    let radix = 10

    for smi in generateSmiValues(countButNotReally: 100) {
      do {
        let smallcase = String(smi, radix: radix, uppercase: false)
        let smallcaseResult = try self.create(string: smallcase, radix: radix)
        XCTAssert(smallcaseResult == smi, "\(smallcaseResult) == \(smi)")

        let uppercase = String(smi, radix: radix, uppercase: true)
        let uppercaseResult = try self.create(string: uppercase, radix: radix)
        XCTAssert(uppercaseResult == smi, "\(uppercaseResult) == \(smi)")
      } catch {
        XCTFail("Error: \(error)")
      }
    }
  }

  // TODO: predefined

  // MARK: - Helpers

  /// Abstraction over `BigInt.init(_:radix:)`.
  private func create(string: String, radix: Int) throws -> BigInt {
    return try BigInt(string, radix: radix)
  }
}
