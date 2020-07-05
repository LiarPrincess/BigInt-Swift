import XCTest
@testable import Core

class BigIntPropertyTests: XCTestCase {

  // MARK: - Eve, odd

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
  // MARK: - Magnitude

  func test_magnitude_int() {
    for raw in generateIntValues(countButNotReally: 100) {
      let int = BigInt(raw)
      let magnitude = int.magnitude

      let expected = raw.magnitude
      XCTAssert(magnitude == expected, "\(raw)")
    }
  }

  func test_manitude_heap() {
    for p in generateHeapValues(countButNotReally: 100) {
      if p.isZero {
        continue
      }

      let positiveHeap = BigIntHeap(isNegative: false, words: p.words)
      let positive = BigInt(positiveHeap)

      let negativeHeap = BigIntHeap(isNegative: true, words: p.words)
      let negative = BigInt(negativeHeap)

      XCTAssertEqual(positive.magnitude, negative.magnitude)
    }
  }
}
