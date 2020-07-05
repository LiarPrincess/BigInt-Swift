import XCTest
@testable import Core

private typealias Word = BigIntStorage.Word

class BigIntHeapSetTests: XCTestCase {

  // MARK: - Set unsigned

  private let unsignedValues: [UInt] = [103, 0, .max, .min]

  func test_set_UInt() {
    var heap = BigIntHeap(isNegative: false, words: 1, 2, 3)

    for value in self.unsignedValues {
      heap.set(to: value)
      XCTAssertEqual(heap, BigIntHeap(isNegative: false, words: value))
    }
  }

  func test_set_UInt_cow() {
    let orginal = BigIntHeap(isNegative: false, words: 1, 2, 3)

    for value in self.unsignedValues {
      var copy = orginal
      copy.set(to: value)

      XCTAssertEqual(orginal, BigIntHeap(isNegative: false, words: 1, 2, 3))
    }
  }

  // MARK: - Set signed

  private let signedValues: [Int] = [103, 0, -104, .max, .min]

  func test_set_Int() {
    var heap = BigIntHeap(isNegative: false, words: 1, 2, 3)

    for value in self.signedValues {
      heap.set(to: value)

      let isNegative = value.isNegative
      let magnitude = value.magnitude
      XCTAssertEqual(heap, BigIntHeap(isNegative: isNegative, words: magnitude))
    }
  }

  func test_set_Int_cow() {
    let orginal = BigIntHeap(isNegative: false, words: 1, 2, 3)

    for value in self.signedValues {
      var copy = orginal
      copy.set(to: value)

      XCTAssertEqual(orginal, BigIntHeap(isNegative: false, words: 1, 2, 3))
    }
  }
}
