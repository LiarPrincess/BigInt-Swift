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
  // smi - trivial
  // heap - same as lowest word
  // TODO: ?

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
  // for every word - not, what with sign?
  // TODO: ?
}
