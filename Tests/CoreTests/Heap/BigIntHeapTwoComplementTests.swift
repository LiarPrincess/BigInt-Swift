import XCTest
@testable import Core

private typealias Word = BigIntStorage.Word

private let smiZero = Smi.Storage.zero
private let smiMax = Smi.Storage.max
private let smiMaxAsWord = Word(smiMax.magnitude)

class BigIntHeapTwoComplementTests: XCTestCase {

  // MARK: - Init

  // MARK: - As two complement

  func test_asTwoComplement_zero() {
    let value = BigIntHeap()
    let complement = value.asTwoComplement()
    XCTAssertTrue(complement.isEmpty)
  }

  func test_asTwoComplement_positive_singleWord() {
    for p in generateHeapValues(countButNotReally: 100, maxWordCount: 1) {
      // We have special test for '0'
      // We only want to test positive numbers
      if p.isZero || p.isNegative {
        continue
      }

      assert(p.words.count == 1)
      let word = p.words[0]

      // '1' as most significant bit means negative number
      // (we have separate test for this)
      let hasMostSignificantBit1 = word >> (Word.bitWidth - 1) == 1
      if hasMostSignificantBit1 {
        continue
      }

      assert(p.isPositive && p.words.count == 1)
      let value = p.create()
      let complement = value.asTwoComplement()

      let expected = BigIntHeap(isNegative: false, words: word)
      XCTAssertEqual(complement, expected.storage, "\(p)")
    }
  }

  func test_asTwoComplement_positive_needsZeroPrefix() {
    let mostSignificantBit1 = Word(1) << (Word.bitWidth - 1)

    for wordCount in 1...3 {
      var words = [Word](repeating: 0, count: wordCount)
      words[wordCount - 1] = mostSignificantBit1

      let value = BigIntHeap(isNegative: false, words: words)
      let complement = value.asTwoComplement()

      let expectedWords = words + [0]
      let expected = BigIntHeap(isNegative: false, words: expectedWords)
      XCTAssertEqual(complement, expected.storage, "\(complement) vs \(expected)")
    }
  }

  func test_asTwoComplement_negative_compareWithInt() {
    for p in generateHeapValues(countButNotReally: 100, maxWordCount: 1) {
      // We have special test for '0'
      // We only want to test negative numbers
      if p.isZero || p.isPositive {
        continue
      }

      assert(p.words.count == 1)
      let word = p.words[0]

      guard let int = Int(exactly: word) else {
        continue
      }

      let value = BigIntHeap(isNegative: true, words: word)
      let complement = value.asTwoComplement()

      let intComplement = -int
      let expectedWord = Word(bitPattern: intComplement)
      let expected = BigIntHeap(isNegative: true, words: expectedWord)

      XCTAssertEqual(complement, expected.storage, "\(p)")
    }
  }

  /// Example for 4-bit word:
  /// Initial: `1000 0000 0001`
  /// Negated: `0111 1111 1110`
  /// Added 1: `0111 1111 1111`
  /// At this point we need `1` prefix to get to: `1111 0111 1111 1111`
  func test_asTwoComplement_negative_needsOnePrefix() {
    let mostSignificantBit1 = Word(1) << (Word.bitWidth - 1)

    for wordCount in 1...3 {
      var words = [Word](repeating: .zero, count: wordCount)
      words[0] |= 1
      words[wordCount - 1] |= mostSignificantBit1

      let value = BigIntHeap(isNegative: true, words: words)
      let complement = value.asTwoComplement()

      // 1111 1111 1111
      var expectedWords = [Word](repeating: .max, count: wordCount)
      // 0111 1111 1111
      expectedWords[wordCount - 1] = ~mostSignificantBit1
      // 1111 0111 1111 1111
      expectedWords.append(.max)

      let expected = BigIntHeap(isNegative: true, words: expectedWords)
      XCTAssertEqual(complement, expected.storage, "\(wordCount)")
    }
  }
}
