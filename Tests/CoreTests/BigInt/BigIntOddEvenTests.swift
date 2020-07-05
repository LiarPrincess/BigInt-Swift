import XCTest
@testable import Core

class BigIntOddEvenTests: XCTestCase {

  func test_smi() {
    for smi in generateSmiValues(countButNotReally: 100) {
      let int = BigInt(smi)

      let expectedEven = smi.isMultiple(of: 2)
      XCTAssertEqual(int.isEven, expectedEven, "\(smi)")
      XCTAssertEqual(int.isOdd, !expectedEven, "\(smi)")
    }
  }

  func test_heap() {
    for p in generateHeapValues(countButNotReally: 100) {
      let heap = p.create()
      let int = BigInt(heap)

      // swiftlint:disable:next legacy_multiple
      let expectedEven = int % 2 == 0
      XCTAssertEqual(int.isEven, expectedEven, "\(heap)")
      XCTAssertEqual(int.isOdd, !expectedEven, "\(heap)")
    }
  }
}
