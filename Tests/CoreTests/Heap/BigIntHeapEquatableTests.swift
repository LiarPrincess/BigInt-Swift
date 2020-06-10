import XCTest
@testable import Core

private typealias Word = BigIntStorage.Word

private let smiZero = Smi.Storage.zero
private let smiMax = Smi.Storage.max
private let smiMin = Smi.Storage.min

class BigIntHeapEquatableTests: XCTestCase {

  // MARK: - Smi

  func test_smi_equal() {
    for smi in self.generateSmiValues(countButNotReally: 100) {
      let heap = BigIntHeap(smi)
      XCTAssertTrue(heap == smi, "\(smi)")
    }
  }

  func test_smi_notEqual() {
    let values = self.generateSmiValues(countButNotReally: 20)

    for (lhs, rhs) in allPossiblePairings(values: values) {
      if lhs == rhs {
        continue
      }

      let lhsHeap = BigIntHeap(lhs)
      XCTAssertFalse(lhsHeap == rhs, "\(lhsHeap) == \(rhs)")

      let rhsHeap = BigIntHeap(rhs)
      XCTAssertFalse(rhsHeap == lhs, "\(rhsHeap) == \(lhs)")
    }
  }

  func test_smi_moreThan1Word() {
    for smi in self.generateSmiValues(countButNotReally: 10) {
      for p in self.generateHeapValues(countButNotReally: 10) {
        guard p.words.count > 1 else {
          continue
        }

        let heap = p.create()
        XCTAssertFalse(heap == smi, "\(heap) == \(smi)")
      }
    }
  }

  /// We will return `2 * countButNotReally + 5` values (don't ask).
  private func generateSmiValues(countButNotReally: Int) -> [Smi.Storage] {
    var result = [Smi.Storage]()
    result.append(0)
    result.append(-1)
    result.append(1)
    result.append(.min)
    result.append(.max)

    let smiSpan = 2 * Int(smiMax) + 1
    let step = smiSpan / countButNotReally

    for i in 0..<countButNotReally {
      let s = i * step

      let fromMax = Smi.Storage(Int(smiMax) - s)
      result.append(fromMax)

      let fromMin = Smi.Storage(Int(smiMin) + s)
      result.append(fromMin)
    }

    return result
  }

  // MARK: - Heap

  func test_heap_equal() {
    for p in self.generateHeapValues(countButNotReally: 100) {
      let lhs = p.create()
      let rhs = p.create()
      XCTAssertEqual(lhs, rhs, "\(lhs)")
    }
  }

  func test_heap_differentSign() {
    for p in self.generateHeapValues(countButNotReally: 100) {
      // '0' is always positive
      if p.isZero {
        continue
      }

      let lhs = BigIntHeap(isNegative: p.isNegative, words: p.words)
      let rhs = BigIntHeap(isNegative: !p.isNegative, words: p.words)
      XCTAssertNotEqual(lhs, rhs, "\(lhs)")
    }
  }

  func test_heap_differentWords() {
    for p in self.generateHeapValues(countButNotReally: 20) {
      // '0' as no words
      if p.isZero {
        continue
      }

      let orginal = p.create()

      for i in 0..<orginal.storage.count {
        // Word can't be above '.max'
        if orginal.storage[i] != .max {
          var plus1 = orginal.storage
          plus1[i] += 1
          XCTAssertNotEqual(orginal, BigIntHeap(storage: plus1), "\(orginal)")
        }

        // Word can't be below '0'
        if orginal.storage[i] != 0 {
          var minus1 = orginal.storage
          minus1[i] -= 1
          XCTAssertNotEqual(orginal, BigIntHeap(storage: minus1), "\(orginal)")
        }
      }
    }
  }

  func test_heap_wordCount() {
    for p in self.generateHeapValues(countButNotReally: 20) {
      let orginal = p.create()

      let moreWords = BigIntHeap(isNegative: p.isNegative, words: p.words + [42])
      XCTAssertNotEqual(orginal, moreWords, "\(orginal)")

      // We can't remove word if we don't have any!
      if !p.isZero {
        let lessWords = BigIntHeap(isNegative: false, words: Array(p.words.dropLast()))
        XCTAssertNotEqual(orginal, lessWords, "\(orginal)")
      }
    }
  }

  private struct HeapPrototype {

    fileprivate let isNegative: Bool
    fileprivate let words: [Word]

    fileprivate var isZero: Bool {
      return self.words.isEmpty
    }

    fileprivate func create() -> BigIntHeap {
      return BigIntHeap(isNegative: self.isNegative, words: self.words)
    }
  }

  /// We will return `2 * countButNotReally + 5` values (don't ask).
  private func generateHeapValues(countButNotReally: Int) -> [HeapPrototype] {
    var result = [HeapPrototype]()
    result.append(HeapPrototype(isNegative: false, words: []))  //  0
    result.append(HeapPrototype(isNegative: false, words: [1])) //  1
    result.append(HeapPrototype(isNegative: true,  words: [1])) // -1
    result.append(HeapPrototype(isNegative: false, words: [.max])) //  Word.max
    result.append(HeapPrototype(isNegative: true,  words: [.max])) // -Word.max

    var word = Word(2) // Start from '2' and go up
    let maxWordCount = 3

    for i in 0..<countButNotReally {
      let atLeast1Word = 1
      let wordCount = i / maxWordCount + atLeast1Word

      var words = [Word]()
      for _ in 0..<wordCount {
        words.append(word)
        word += 1
      }

      result.append(HeapPrototype(isNegative: false, words: words))
      result.append(HeapPrototype(isNegative: true, words: words))
    }

    return result
  }
}
