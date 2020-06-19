import XCTest
@testable import Core

private typealias Word = BigIntStorage.Word

private let smiZero = Smi.Storage.zero
private let smiMax = Smi.Storage.max
private let smiMaxAsWord = Word(smiMax.magnitude)

class BigIntHeapMulTests: XCTestCase {

  // MARK: - Smi - 0

  func test_smi_otherZero() {
    let expectedZero = BigIntHeap()

    for p in generateHeapValues(countButNotReally: 100) {
      var value = p.create()
      value.mul(other: smiZero)

      XCTAssertEqual(value, expectedZero)
    }
  }

  func test_smi_selfZero() {
    let expectedZero = BigIntHeap()

    for smi in generateSmiValues(countButNotReally: 100) {
      var value = BigIntHeap()
      value.mul(other: smi)

      XCTAssertEqual(value, expectedZero)
    }
  }

  // MARK: - Smi - +1

  func test_smi_otherPlusOne() {
    for p in generateHeapValues(countButNotReally: 100) {
      var value = p.create()
      value.mul(other: Smi.Storage(1))

      let noChanges = p.create()
      XCTAssertEqual(value, noChanges)
    }
  }

  func test_smi_selfPlusOne() {
    for smi in generateSmiValues(countButNotReally: 100) {
      var value = BigIntHeap(1)
      value.mul(other: smi)

      let expected = BigIntHeap(smi)
      XCTAssertEqual(value, expected)
    }
  }

  // MARK: - Smi - -1

  func test_smi_otherMinusOne() {
    for p in generateHeapValues(countButNotReally: 100) {
      var value = p.create()
      value.mul(other: Smi.Storage(-1))

      let expectedIsNegative = p.isPositive && !p.isZero
      let expected = BigIntHeap(isNegative: expectedIsNegative, words: p.words)
      XCTAssertEqual(value, expected)
    }
  }

  func test_smi_selfMinusOne() {
    for smi in generateSmiValues(countButNotReally: 100) {
      // '-Smi.min' overflows
      if smi == .min {
        continue
      }

      var value = BigIntHeap(-1)
      value.mul(other: smi)

      let expected = BigIntHeap(-smi)
      XCTAssertEqual(value, expected)
    }
  }

  // MARK: - Smi pow 2

  /// `2^n = value`
  private typealias Pow2 = (value: Int, n: Int)

  /// Mul by power of `n^2` should shift left by `n`
  func test_smi_otherIsPowerOf2() {
    let powers: [Pow2] = [
      (value: 2, n: 1),
      (value: 4, n: 2),
      (value: 16, n: 4)
    ]

    for p in generateHeapValues(countButNotReally: 100) {
      if p.isZero {
        continue
      }

      for (power, n) in powers {
        let maxBeforeShift = 1 << (Word.bitWidth - n)
        let doesNotShiftOutsideOfWord = p.words.allSatisfy { $0 < maxBeforeShift }
        guard doesNotShiftOutsideOfWord else {
          continue
        }

        var value = p.create()
        value.mul(other: Smi.Storage(power))

        let expectedWord4 = p.words.map { $0 << n }
        let expected4 = BigIntHeap(isNegative: p.isNegative, words: expectedWord4)
        XCTAssertEqual(value, expected4, "\(p) * \(power)")
      }
    }
  }
}
