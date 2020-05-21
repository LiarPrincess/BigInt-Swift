import XCTest
@testable import BigInt

private typealias Storage = Smi.Storage

class SmiUnaryTests: XCTestCase {

  // MARK: - Minus

  func test_minus() {
    // Do not add 'Storage.min', it is out of range of 'Smi'!
    // There is a special test for this.
    let values: [Storage] = [0, 42, .max, -42]

    for value in values {
      let smi = Smi(value)
      let expected = BigInt(smi: -value)
      XCTAssertEqual(smi.minus, expected, String(describing: value))
    }
  }

  func test_minus_min() {
    // We are going to hard-code some values, otherwise we would have to copy
    // production code to make this test work.
    let minSmi = -2147483648
    XCTAssert(Storage.min == minSmi)

    guard let minSmi32 = Int32(exactly: minSmi) else {
      XCTAssert(false, "Changed Smi.Storage?")
      return
    }

    let smi = Smi(minSmi32)
    let expected = BigInt(-minSmi)
    XCTAssertEqual(smi.minus, expected)
  }

  // MARK: - Invert
}
