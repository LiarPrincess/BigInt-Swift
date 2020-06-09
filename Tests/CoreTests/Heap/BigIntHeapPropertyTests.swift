import XCTest
@testable import Core

private typealias Word = BigIntStorage.Word

class BigIntHeapPropertyTests: XCTestCase {

  // MARK: - Is zero

  private let nonZeroValues: [Word] = [103, .max, 42, 43]

  func test_isZero() {
    let zero = BigIntHeap(0)
    XCTAssertTrue(zero.isZero)

    for (word0, word1) in allPossiblePairings(values: self.nonZeroValues) {
      let positive = BigIntHeap(isNegative: false, words: word0, word1)
      XCTAssertFalse(positive.isZero)

      let negative = BigIntHeap(isNegative: true, words: word0, word1)
      XCTAssertFalse(negative.isZero)
    }
  }

  // MARK: - Is positive

  func test_isPositive() {
    let zero = BigIntHeap(0)
    XCTAssertTrue(zero.isPositive)

    for (word0, word1) in allPossiblePairings(values: self.nonZeroValues) {
      let positive = BigIntHeap(isNegative: false, words: word0, word1)
      XCTAssertTrue(positive.isPositive)

      let negative = BigIntHeap(isNegative: true, words: word0, word1)
      XCTAssertFalse(negative.isPositive)
    }
  }

  // MARK: - Is negative

  func test_isNegative() {
    let zero = BigIntHeap(0)
    XCTAssertFalse(zero.isNegative)

    for (word0, word1) in allPossiblePairings(values: self.nonZeroValues) {
      let positive = BigIntHeap(isNegative: false, words: word0, word1)
      XCTAssertFalse(positive.isNegative)

      let negative = BigIntHeap(isNegative: true, words: word0, word1)
      XCTAssertTrue(negative.isNegative)
    }
  }

  // MARK: - Has magnitude of 1

  func test_hasMagnitudeOfOne_true() {
    let positive = BigIntHeap(1)
    XCTAssertTrue(positive.hasMagnitudeOfOne)
    XCTAssertTrue(positive.isPositive)

    let negative = BigIntHeap(-1)
    XCTAssertTrue(negative.hasMagnitudeOfOne)
    XCTAssertTrue(negative.isNegative)
  }

  func test_hasMagnitudeOfOne_false() {
    let zero = BigIntHeap(0)
    XCTAssertFalse(zero.hasMagnitudeOfOne)

    for (word0, word1) in allPossiblePairings(values: self.nonZeroValues) {
      let positive = BigIntHeap(isNegative: false, words: word0, word1)
      XCTAssertFalse(positive.hasMagnitudeOfOne)

      let negative = BigIntHeap(isNegative: true, words: word0, word1)
      XCTAssertFalse(negative.hasMagnitudeOfOne)
    }
  }
}
