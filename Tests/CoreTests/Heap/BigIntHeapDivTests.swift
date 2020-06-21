import XCTest
@testable import Core

// swiftlint:disable line_length
// swiftlint:disable number_separator
// swiftlint:disable file_length

private typealias Word = BigIntStorage.Word

private let smiZero = Smi.Storage.zero
private let smiMax = Smi.Storage.max
private let smiMaxAsWord = Word(smiMax.magnitude)

/// `2^n = value`
private typealias Pow2 = (value: Int, n: Int)

private let powersOf2: [Pow2] = [
  (value: 2, n: 1),
  (value: 4, n: 2),
  (value: 16, n: 4)
]

class BigIntHeapDivTests: XCTestCase {

  // MARK: - Smi - 0

  // For obvious reasons we will not have 'otherZero' test

  /// 0 / x = 0 rem 0
  func test_smi_selfZero() {
    for smi in generateSmiValues(countButNotReally: 100) {
      if smi.isZero {
        continue
      }

      var value = BigIntHeap()
      let rem = value.div(other: smi)

      XCTAssert(value.isZero)
      XCTAssert(rem.isZero)
    }
  }

  // MARK: - Smi - +1

  /// x / 1 = x rem 0
  func test_smi_otherPlusOne() {
    for p in generateHeapValues(countButNotReally: 100) {
      var value = p.create()
      let rem = value.div(other: Smi.Storage(1))

      let noChanges = p.create()
      XCTAssertEqual(value, noChanges)
      XCTAssert(rem.isZero)
    }
  }

  /// 1 / x = 0 rem 1 (mostly)
  func test_smi_selfPlusOne() {
    for smi in generateSmiValues(countButNotReally: 100) {
      if smi.isZero {
        continue
      }

      var value = BigIntHeap(1)
      let rem = value.div(other: smi)

      switch smi {
      case 1: // 1 / 1 = 1 rem 0
        XCTAssertEqual(value, BigIntHeap(1))
        XCTAssert(rem.isZero)
      case -1: // 1 / (-1) = -1 rem 0
        XCTAssertEqual(value, BigIntHeap(-1))
        XCTAssert(rem.isZero)
      default:
        XCTAssert(value.isZero, "1 / \(smi)")
        XCTAssert(rem == 1, "1 / \(smi)") // Always positive!
      }
    }
  }

  // MARK: - Smi - -1

  /// x / (-1) = -x
  func test_smi_otherMinusOne() {
    for p in generateHeapValues(countButNotReally: 100) {
      var value = p.create()
      let rem = value.div(other: Smi.Storage(-1))

      let expectedIsNegative = p.isPositive && !p.isZero
      let expected = BigIntHeap(isNegative: expectedIsNegative, words: p.words)
      XCTAssertEqual(value, expected)
      XCTAssert(rem.isZero)
    }
  }

  /// (-1) / x = 0 rem -1 (mostly)
  func test_smi_selfMinusOne() {
    for smi in generateSmiValues(countButNotReally: 100) {
      if smi.isZero {
        continue
      }

      var value = BigIntHeap(-1)
      let rem = value.div(other: smi)

      switch smi {
      case 1: // (-1) / 1 = -1 rem 0
        XCTAssertEqual(value, BigIntHeap(-1))
        XCTAssert(rem.isZero)
      case -1: // (-1) / (-1) = 1 rem 0
        XCTAssertEqual(value, BigIntHeap(1))
        XCTAssert(rem.isZero)
      default:
        XCTAssert(value.isZero)
        XCTAssertEqual(rem, -1)
      }
    }
  }

  // MARK: - Smi pow 2

  /// Div by `n^2` should shift right by `n`
  func test_smi_otherIsPowerOf2() {
    for p in generateHeapValues(countButNotReally: 100) {
      if p.isZero {
        continue
      }

      for power in powersOf2 {
        guard let p = self.cleanBitsSoItCanBeDividedWithoutOverflow(
          value: p,
          power: power
        ) else { continue }

        var value = p.create()
        let rem = value.div(other: Smi.Storage(power.value))

        let expectedWords = p.words.map { $0 >> power.n }
        var expected = BigIntHeap(isNegative: p.isNegative, words: expectedWords)
        expected.fixInvariants()

        XCTAssertEqual(value, expected, "\(p) / \(power.value)")
        // Rem is '0' because we cleaned those bits
        XCTAssert(rem.isZero, "\(p) / \(power.value)")
      }
    }
  }

  private func cleanBitsSoItCanBeDividedWithoutOverflow(
    value: HeapPrototype,
    power: Pow2
  ) -> HeapPrototype? {
    // 1111 << 1 = 1110
    let mask = Word.max << power.n
    let words = value.words.map { $0 & mask }

    // Zero may behave differently than other numbers
    let allWordsZero = words.allSatisfy { $0.isZero }
    if allWordsZero {
      return nil
    }

    return HeapPrototype(isNegative: value.isNegative, words: words)
  }

  /// x / x = 1 rem 0
  func test_smi_equalMagnitude() {
    let one = BigIntHeap(1)

    for smi in generateSmiValues(countButNotReally: 100) {
      if smi == 0 {
        continue
      }

      var value = BigIntHeap(smi)
      let rem = value.div(other: smi)

      XCTAssertEqual(value, one)
      XCTAssert(rem.isZero)
    }
  }

  /// x / (x-n) = 1 rem n
  func test_smi_selfHas_greaterMagnitude() {
    let values = generateSmiValues(countButNotReally: 20)

    for (lhs, rhs) in allPossiblePairings(values: values) {
      // We have separate test for equal magnitude
      if lhs.magnitude == rhs.magnitude {
        continue
      }

      let (valueSmi, otherSmi) = lhs.magnitude > rhs.magnitude ?
        (lhs, rhs) : (rhs, lhs)

      if otherSmi == 0 {
        continue
      }

      var value = BigIntHeap(valueSmi)
      let rem = value.div(other: otherSmi)

      // We have to convert to 'Int' because: min / -1' = (max + 1) = overflow
      let expectedDiv = Int(valueSmi) / Int(otherSmi)
      let expectedRem = Int(valueSmi) % Int(otherSmi)
      XCTAssertEqual(value, BigIntHeap(expectedDiv))
      XCTAssertEqual(Int(rem), expectedRem, "\(valueSmi) / \(otherSmi)")
    }
  }

  /// x / (x + n) = 0 rem x
  func test_smi_otherHas_greaterMagnitude() {
    let values = generateSmiValues(countButNotReally: 20)

    for (lhs, rhs) in allPossiblePairings(values: values) {
      // We have separate test for equal magnitude
      if lhs.magnitude == rhs.magnitude {
        continue
      }

      let (valueSmi, otherSmi) = lhs.magnitude < rhs.magnitude ?
        (lhs, rhs) : (rhs, lhs)

      if otherSmi == 0 {
        continue
      }

      var value = BigIntHeap(valueSmi)
      let rem = value.div(other: otherSmi)

      XCTAssert(value.isZero)
      XCTAssertEqual(rem, valueSmi)
    }
  }

  // MARK: - Smi - Self has multiple words

  func test_smi_lhsLonger() {
    let lhsWords: [Word] = [3689348814741910327, 2459565876494606880]
    let rhs: Smi.Storage = 370955168

    let expectedDivWords: [Word] = [10690820303666397895, 6630358837]
    let expectedRem: Smi.Storage = 237957591

    // Both positive
    var lhs = BigIntHeap(isNegative: false, words: lhsWords)
    var rem = lhs.div(other: rhs)
    XCTAssertEqual(lhs, BigIntHeap(isNegative: false, words: expectedDivWords))
    XCTAssertEqual(rem, expectedRem)

    // Self negative, other positive
    lhs = BigIntHeap(isNegative: true, words: lhsWords)
    rem = lhs.div(other: rhs)
    XCTAssertEqual(lhs, BigIntHeap(isNegative: true, words: expectedDivWords))
    XCTAssertEqual(rem, -expectedRem)

    // Self positive, other negative
    lhs = BigIntHeap(isNegative: false, words: lhsWords)
    rem = lhs.div(other: -rhs)
    XCTAssertEqual(lhs, BigIntHeap(isNegative: true, words: expectedDivWords))
    XCTAssertEqual(rem, expectedRem)

    // Both negative
    lhs = BigIntHeap(isNegative: true, words: lhsWords)
    rem = lhs.div(other: -rhs)
    XCTAssertEqual(lhs, BigIntHeap(isNegative: false, words: expectedDivWords))
    XCTAssertEqual(rem, -expectedRem)
  }
}
