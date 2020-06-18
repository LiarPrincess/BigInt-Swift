import XCTest
@testable import Core

// swiftlint:disable number_separator

private typealias Word = BigIntStorage.Word
private typealias Words = [Word]
private typealias TestTriple = (lhs: Words, rhs: Words, result: Words)

class BigIntHeapAndTests: XCTestCase {

  // MARK: - Heap

  func test_heap_selfZero() {
    let zero = BigIntHeap()

    for rhsInt in generateIntValues(countButNotReally: 10) {
      let rhsWord = Word(rhsInt.magnitude)
      let rhs = BigIntHeap(isNegative: rhsInt.isNegative, words: rhsWord)

      var lhs = BigIntHeap()
      lhs.and(other: rhs)

      XCTAssertEqual(lhs, zero)
    }
  }

  func test_heap_otherZero() {
    let zero = BigIntHeap()

    for lhsInt in generateIntValues(countButNotReally: 10) {
      let lhsWord = Word(lhsInt.magnitude)
      var lhs = BigIntHeap(isNegative: lhsInt.isNegative, words: lhsWord)

      lhs.and(other: zero)

      XCTAssertEqual(lhs, zero)
    }
  }

  func test_heap_singleWord_trivial() {
    let lhsWord: Word = 0b1100
    let rhsWord: Word = 0b1010

    var lhs = BigIntHeap(isNegative: false, words: lhsWord)
    let rhs = BigIntHeap(isNegative: false, words: rhsWord)
    lhs.and(other: rhs)

    let expected = lhsWord & rhsWord
    XCTAssertEqual(lhs, BigIntHeap(expected))
  }

  func test_heap_singleWord() {
    let values = generateIntValues(countButNotReally: 10)

    for (lhsInt, rhsInt) in allPossiblePairings(values: values) {
      let lhsWord = Word(lhsInt.magnitude)
      let rhsWord = Word(rhsInt.magnitude)

      var lhs = BigIntHeap(isNegative: lhsInt.isNegative, words: lhsWord)
      let rhs = BigIntHeap(isNegative: rhsInt.isNegative, words: rhsWord)
      lhs.and(other: rhs)

      let expectedInt = lhsInt & rhsInt
      let expected = BigIntHeap(expectedInt)

      print("\(lhsInt) & \(rhsInt) = \(lhs)")
      XCTAssertEqual(lhs, expected, "\(lhsInt) & \(rhsInt)")
    }
  }

  func test_heap_lhsLonger() {
    let lhsWords: [Word] = [3689348814741910327, 2459565876494606880]
    let rhsWords: [Word] = [1844674407370955168]

    // Both positive
    var lhs = BigIntHeap(isNegative: false, words: lhsWords)
    var rhs = BigIntHeap(isNegative: false, words: rhsWords)
    var expected = BigIntHeap(isNegative: false, words: 1229782938247303456)

    lhs.and(other: rhs)
    XCTAssertEqual(lhs, expected)

    // Self negative, other positive
    lhs = BigIntHeap(isNegative: true, words: lhsWords)
    rhs = BigIntHeap(isNegative: false, words: rhsWords)
    expected = BigIntHeap(isNegative: false, words: 614891469123651712)

    lhs.and(other: rhs)
    XCTAssertEqual(lhs, expected)

    // Self positive, other negative
    lhs = BigIntHeap(isNegative: false, words: lhsWords)
    rhs = BigIntHeap(isNegative: true, words: rhsWords)
    expected = BigIntHeap(isNegative: false, words: [2459565876494606880, 2459565876494606880])

    lhs.and(other: rhs)
    XCTAssertEqual(lhs, expected)

    // Both negative
    lhs = BigIntHeap(isNegative: true, words: lhsWords)
    rhs = BigIntHeap(isNegative: true, words: rhsWords)
    expected = BigIntHeap(isNegative: true, words: [4304240283865562048, 2459565876494606880])

    lhs.and(other: rhs)
    XCTAssertEqual(lhs, expected)
  }

  func test_heap_rhsLonger() {
    let lhsWords: [Word] = [1844674407370955168]
    let rhsWords: [Word] = [3689348814741910327, 2459565876494606880]

    // Both positive
    var lhs = BigIntHeap(isNegative: false, words: lhsWords)
    var rhs = BigIntHeap(isNegative: false, words: rhsWords)
    var expected = BigIntHeap(isNegative: false, words: 1229782938247303456)

    lhs.and(other: rhs)
    XCTAssertEqual(lhs, expected)

    // Self negative, other positive
    lhs = BigIntHeap(isNegative: true, words: lhsWords)
    rhs = BigIntHeap(isNegative: false, words: rhsWords)
    expected = BigIntHeap(isNegative: false, words: [2459565876494606880, 2459565876494606880])

    lhs.and(other: rhs)
    XCTAssertEqual(lhs, expected)

    // Self positive, other negative
    lhs = BigIntHeap(isNegative: false, words: lhsWords)
    rhs = BigIntHeap(isNegative: true, words: rhsWords)
    expected = BigIntHeap(isNegative: false, words: 614891469123651712)

    lhs.and(other: rhs)
    XCTAssertEqual(lhs, expected)

    // Both negative
    lhs = BigIntHeap(isNegative: true, words: lhsWords)
    rhs = BigIntHeap(isNegative: true, words: rhsWords)
    expected = BigIntHeap(isNegative: true, words: [4304240283865562048, 2459565876494606880])

    lhs.and(other: rhs)
    XCTAssertEqual(lhs, expected)
  }

  // both have 2 words
  func test_heap_bothMultipleWords() {
    let lhsWords: [Word] = [1844674407370955168, 4304240283865562048]
    let rhsWords: [Word] = [3689348814741910327, 2459565876494606880]

    // Both positive
    var lhs = BigIntHeap(isNegative: false, words: lhsWords)
    var rhs = BigIntHeap(isNegative: false, words: rhsWords)
    var expected = BigIntHeap(isNegative: false, words: [1229782938247303456, 2459565876494606848])

    lhs.and(other: rhs)
    XCTAssertEqual(lhs, expected)

    // Self negative, other positive
    lhs = BigIntHeap(isNegative: true, words: lhsWords)
    rhs = BigIntHeap(isNegative: false, words: rhsWords)
    expected = BigIntHeap(isNegative: false, words: [2459565876494606880, 32])

    lhs.and(other: rhs)
    XCTAssertEqual(lhs, expected)

    // Self positive, other negative
    lhs = BigIntHeap(isNegative: false, words: lhsWords)
    rhs = BigIntHeap(isNegative: true, words: rhsWords)
    expected = BigIntHeap(isNegative: false, words: [614891469123651712, 1844674407370955200])

    lhs.and(other: rhs)
    XCTAssertEqual(lhs, expected)

    // Both negative
    lhs = BigIntHeap(isNegative: true, words: lhsWords)
    rhs = BigIntHeap(isNegative: true, words: rhsWords)
    expected = BigIntHeap(isNegative: true, words: [4304240283865562048, 4304240283865562080])

    lhs.and(other: rhs)
    XCTAssertEqual(lhs, expected)
  }
}
