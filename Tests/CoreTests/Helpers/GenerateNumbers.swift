@testable import Core

private typealias Word = BigIntStorage.Word

private let smiZero = Smi.Storage.zero
private let smiMax = Smi.Storage.max
private let smiMin = Smi.Storage.min

// MARK: - Smi

/// We will return `2 * countButNotReally + 5` values (don't ask).
internal func generateSmiValues(countButNotReally: Int) -> [Smi.Storage] {
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

internal struct HeapPrototype {

  internal let isNegative: Bool
  internal let words: [BigIntStorage.Word]

  internal var isZero: Bool {
    return self.words.isEmpty
  }

  internal func create() -> BigIntHeap {
    return BigIntHeap(isNegative: self.isNegative, words: self.words)
  }
}

/// We will return `2 * countButNotReally + 5` values (don't ask).
internal func generateHeapValues(countButNotReally: Int) -> [HeapPrototype] {
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
