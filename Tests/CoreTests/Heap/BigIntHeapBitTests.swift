import XCTest
@testable import Core

private typealias Word = BigIntStorage.Word

private let smiZero = Smi.Storage.zero
private let smiMax = Smi.Storage.max
private let smiMaxAsWord = Word(smiMax.magnitude)

class BigIntHeapBitTests: XCTestCase {

  // MARK: - Words
  // smi - trivial
  // heap - ? check if this is 2 complement ?
  // TODO: ?

  // MARK: - Bit width
  // ?
  // TODO: ?

  // MARK: - Trailing zero bit count

  func test_trailingZeroBitCount_zero() {
    // There is an edge case for '0':
    // - 'int' is finite, so they can return 'bitWidth'
    // - 'BigInt' is infinite, but we cant return that

    let zero = BigIntHeap()
    let result = zero.trailingZeroBitCount
    XCTAssertEqual(result, 0)
  }

  func test_trailingZeroBitCount_singleWord() {
    for int in generateIntValues(countButNotReally: 100) {
      // We have separate test for this
      if int.isZero {
        continue
      }

      let value = BigIntHeap(int)
      let result = value.trailingZeroBitCount

      let expected = int.trailingZeroBitCount
      XCTAssertEqual(result, expected, "\(int)")
    }
  }

  func test_trailingZeroBitCount_multipleWords() {
    for int0 in generateIntValues(countButNotReally: 10) {
      let word0 = Word(bitPattern: int0)

      for int1 in generateIntValues(countButNotReally: 10) {
        let word1 = Word(bitPattern: int1)

        // That would require 3rd word (which we don't have)
        if word0 == 0 && word1 == 0 {
          continue
        }

        let value = BigIntHeap(isNegative: int0.isNegative, words: word0, word1)
        let result = value.trailingZeroBitCount

        let expected = word0 != 0 ?
          word0.trailingZeroBitCount :
          Word.bitWidth + word1.trailingZeroBitCount

        XCTAssertEqual(result, expected, "\(word0) \(word1)")
      }
    }
  }

  // MARK: - Negate

  func test_negate_zero() {
    var zero = BigIntHeap(0)
    zero.negate()

    let alsoZero = BigIntHeap(0)
    XCTAssertEqual(zero, alsoZero)
  }

  func test_negate_smi() {
    for smi in generateSmiValues(countButNotReally: 100) {
      // 'Smi.min' negation overflows
      if smi == .min {
        continue
      }

      var value = BigIntHeap(smi)
      value.negate()

      let expected = -smi
      XCTAssertTrue(value == expected, "\(value) == \(expected)")
    }
  }

  func test_negate_heap() {
    for p in generateHeapValues(countButNotReally: 100) {
      // There is special test for '0'
      if p.isZero {
        continue
      }

      var value = p.create()

      // Single negation
      value.negate()
      XCTAssertEqual(value.isNegative, !p.isNegative)

      // Same magnitude?
      XCTAssertEqual(value.storage.count, p.words.count)
      for (negatedWord, orginalWord) in zip(value.storage, p.words) {
        XCTAssertEqual(negatedWord, orginalWord)
      }

      // Double negation - back to normal
      value.negate()
      XCTAssertEqual(value.isNegative, p.isNegative)

      // Same magnitude?
      XCTAssertEqual(value.storage.count, p.words.count)
      for (negatedWord, orginalWord) in zip(value.storage, p.words) {
        XCTAssertEqual(negatedWord, orginalWord)
      }
    }
  }

  // MARK: - Invert

  func test_invert_singleWord() {
    for int in generateIntValues(countButNotReally: 100) {
      var value = BigIntHeap(int)
      value.invert()

      let expectedValue = ~int
      let expected = BigIntHeap(expectedValue)
      XCTAssertEqual(value, expected)

      XCTAssertEqual(int + expectedValue, -1)
    }
  }

  func test_invert_multipleWords() {
    let minus1 = BigIntHeap(-1)

    for p in generateHeapValues(countButNotReally: 100) {
      var value = p.create()
      value.invert()

      // We always change sign, '0' becomes '-1'
      XCTAssertEqual(value.isNegative, !p.isNegative, "\(p)")

      // x + (~x) = -1
      let orginal = p.create()
      value.add(other: orginal)
      XCTAssertEqual(value, minus1, "\(p)")
    }
  }
}
