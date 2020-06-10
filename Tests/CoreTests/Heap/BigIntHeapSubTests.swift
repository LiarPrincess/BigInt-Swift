import XCTest
@testable import Core

private typealias Word = BigIntStorage.Word

private let smiZero = Smi.Storage.zero
private let smiMax = Smi.Storage.max
private let smiMaxAsWord = Word(smiMax.magnitude)

class BigIntHeapSubTests: XCTestCase {

  // MARK: - Smi - zero

  /// smiMax - 0 = smiMax
  func test_smi_selfPositive_otherZero() {
    var value = BigIntHeap(isNegative: false, words: smiMaxAsWord)
    value.sub(other: smiZero)

    let expected = BigIntHeap(isNegative: false, words: smiMaxAsWord)
    XCTAssertEqual(value, expected)
  }

  /// -smiMax + 0 = -smiMax
  func test_smi_selfNegative_otherZero() {
    var value = BigIntHeap(isNegative: true, words: smiMaxAsWord)
    value.sub(other: smiZero)

    let expected = BigIntHeap(isNegative: true, words: smiMaxAsWord)
    XCTAssertEqual(value, expected)
  }

  /// 0 - smiMax = -smiMax
  func test_smi_selfZero_otherPositive() {
    var value = BigIntHeap()
    value.sub(other: smiMax)

    let expected = BigIntHeap(isNegative: true, words: smiMaxAsWord)
    XCTAssertEqual(value, expected)
  }

  /// 0 - (-smiMax) = smiMax
  func test_smi_selfZero_otherNegative() {
    var value = BigIntHeap()
    value.sub(other: -smiMax)

    let expected = BigIntHeap(isNegative: false, words: smiMaxAsWord)
    XCTAssertEqual(value, expected)
  }

  // MARK: - Smi - both positive

  /// Word.max - smiMax = well... something
  func test_smi_bothPositive_sameSign() {
    var value = BigIntHeap(isNegative: false, words: Word.max)
    value.sub(other: smiMax)

    let expected = BigIntHeap(isNegative: false, words: Word.max - smiMaxAsWord)
    XCTAssertEqual(value, expected)
  }

  /// smiMax - smiMax = 0
  func test_smi_bothPositive_zero() {
    var value = BigIntHeap(isNegative: false, words: smiMaxAsWord)
    value.sub(other: smiMax)

    let expected = BigIntHeap() // zero
    XCTAssertEqual(value, expected)
  }

  /// 10 - smiMax =  -(smiMax - 10)
  func test_smi_bothPositive_changingSign() {
    var value = BigIntHeap(isNegative: false, words: 10)
    value.sub(other: smiMax)

    let expected = BigIntHeap(isNegative: true, words: smiMaxAsWord - 10)
    XCTAssertEqual(value, expected)
  }

  // MARK: - Smi - both negative

  /// -Word.max - (-smiMax) = well... something
  func test_smi_bothNegative_sameSign() {
    var value = BigIntHeap(isNegative: true, words: Word.max)
    value.sub(other: -smiMax)

    let expected = BigIntHeap(isNegative: true, words: Word.max - smiMaxAsWord)
    XCTAssertEqual(value, expected)
  }

  /// -smiMax - (-smiMax) = 0
  func test_smi_bothNegative_zero() {
    var value = BigIntHeap(isNegative: true, words: smiMaxAsWord)
    value.sub(other: -smiMax)

    let expected = BigIntHeap() // zero
    XCTAssertEqual(value, expected)
  }

  /// 10 - smiMax =  -(smiMax - 10)
  func test_smi_bothNegative_changingSign() {
    var value = BigIntHeap(isNegative: true, words: 10)
    value.sub(other: -smiMax)

    let expected = BigIntHeap(isNegative: false, words: smiMaxAsWord - 10)
    XCTAssertEqual(value, expected)
  }

  // MARK: - Smi - positive negative

  /// (Word.max - smiMax) - (-smiMax) = Word.max
  func test_smi_selfPositive_otherNegative_sameWord() {
    var value = BigIntHeap(isNegative: false, words: Word.max - smiMaxAsWord)
    value.sub(other: -smiMax)

    let expected = BigIntHeap(isNegative: false, words: Word.max)
    XCTAssertEqual(value, expected)
  }

  /// Word.max +- (-smiMax) = well... a lot
  func test_smi_selfPositive_otherNegative_newWord() {
    var value = BigIntHeap(isNegative: false, words: Word.max)
    value.sub(other: -smiMax)

    // Why '-1'? 99 + 5 = 104, not 105!
    let expected = BigIntHeap(isNegative: false, words: smiMaxAsWord - 1, 1)
    XCTAssertEqual(value, expected)
  }

  // MARK: - Smi - negative positive

  /// -(Word.max - smiMax) - smiMax = -Word.max
  func test_smi_selfNegative_otherPositive_sameWord() {
    var value = BigIntHeap(isNegative: true, words: Word.max - smiMaxAsWord)
    value.sub(other: smiMax)

    let expected = BigIntHeap(isNegative: true, words: Word.max)
    XCTAssertEqual(value, expected)
  }

  /// -Word.max - smiMax = well... a lot
  func test_smi_selfNegative_otherPositive_newWord() {
    var value = BigIntHeap(isNegative: true, words: Word.max)
    value.sub(other: smiMax)

    // Why '-1'? 99 + 5 = 104, not 105!
    let expected = BigIntHeap(isNegative: true, words: smiMaxAsWord - 1, 1)
    XCTAssertEqual(value, expected)
  }
}
