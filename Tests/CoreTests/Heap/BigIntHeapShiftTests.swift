import XCTest
@testable import Core

private typealias Word = BigIntStorage.Word

private let smiZero = Smi.Storage.zero
private let smiMax = Smi.Storage.max
private let smiMaxAsWord = Word(smiMax.magnitude)

class BigIntHeapShiftTests: XCTestCase {

  // MARK: - Left

  func test_left_byZero() {
    for p in generateHeapValues(countButNotReally: 100) {
      var value = p.create()
      value.shiftLeft(count: Smi.Storage(0))

      let expected = p.create()
      XCTAssertEqual(value, expected)
    }
  }

  func test_left_byWholeWord() {
    for p in generateHeapValues(countButNotReally: 35) {
      // Shifting '0' obeys a bit different rules
      if p.isZero {
        continue
      }

      for wordShift in 1...3 {
        var value = BigIntHeap(isNegative: p.isNegative, words: p.words)

        let prefix = [Word](repeating: 0, count: wordShift)
        let expected = BigIntHeap(isNegative: p.isNegative, words: prefix + p.words)

        let bitShift = wordShift * Word.bitWidth
        value.shiftLeft(count: Smi.Storage(bitShift))
        XCTAssertEqual(value, expected)
      }
    }
  }

  func test_left_byBits() {
    // We will be shifting by 3 bits, make sure that they are 0,
    // so that we stay inside 1 word.
    let hasPlaceToShiftMask = Word(0b111) << (Word.bitWidth - 3)

    for p in generateHeapValues(countButNotReally: 50, maxWordCount: 1) {
      // Shifting '0' obeys a bit different rules
      if p.isZero {
        continue
      }

      assert(p.words.count == 1)
      let word = p.words[0]

      let hasPlaceToShift = (word & hasPlaceToShiftMask) == 0
      guard hasPlaceToShift else {
        continue
      }

      for count in 1...3 {
        var value = p.create()

        let expectedBeforeShift = p.isNegative ? -Int(word) : Int(word)
        let expectedAfterShift = expectedBeforeShift << count
        let expected = BigIntHeap(expectedAfterShift)

        value.shiftLeft(count: Smi.Storage(count))
        XCTAssertEqual(value, expected, "\(value) == \(expected)")
      }
    }
  }

  func test_left_exampleFromCode() {
    let word = Word(bitPattern: 1 << (Word.bitWidth - 1) | 0b0011)
    var value = BigIntHeap(isNegative: false, words: word)

    let shiftCount = Smi.Storage(Word.bitWidth + 1)
    value.shiftLeft(count: shiftCount)

    let expected = BigIntHeap(isNegative: false, words: 0b0000, 0b0110, 0b0001)
    XCTAssertEqual(value, expected)
  }

  // TODO: test_left_butActuallyRight()
}
