import XCTest
@testable import Core

private typealias Word = BigIntStorage.Word

class BigIntStorageTests: XCTestCase {

  // MARK: - Memory layout

  private enum FutureBigInt {
    case smi(Smi)
    case ptr(BigIntStorage)
  }

  func test_memoryLayout() {
    XCTAssertEqual(MemoryLayout<FutureBigInt>.size, 8)
    XCTAssertEqual(MemoryLayout<FutureBigInt>.stride, 8)
  }

  // MARK: - Subscript

  func test_subscript_get() {
    let storage: BigIntStorage = [0, 1, 2, 3]

    for i in 0..<storage.count {
      XCTAssertEqual(storage[i], Word(i))
    }
  }

  func test_subscript_set() {
    let storage: BigIntStorage = [0, 1, 2, 3]

    for i in 0..<storage.count {
      storage[i] += 1
      XCTAssertEqual(storage[i], Word(i + 1))
    }
  }

  // MARK: - Append

  func test_append() {
    let count = 4
    var storage = BigIntStorage(minimumCapacity: count)

    for i in 0..<count {
      storage.append(Word(i))
    }

    for i in 0..<count {
      XCTAssertEqual(storage[i], Word(i))
    }
  }

  func test_append_withGrow() {
    var storage = BigIntStorage(minimumCapacity: 4)

    let oldCapacity = storage.capacity
    for i in 0..<oldCapacity {
      storage.append(Word(i))
    }
    XCTAssertEqual(storage.capacity, oldCapacity)

    storage.append(100)

    XCTAssertNotEqual(storage.capacity, oldCapacity)
    XCTAssertGreaterThan(storage.capacity, oldCapacity)

    for i in 0..<oldCapacity {
      XCTAssertEqual(storage[i], Word(i))
    }
    XCTAssertEqual(storage[storage.count - 1], Word(100))
  }

  // MARK: - Description

  /// Please note that `capacity` is implementation dependent,
  /// if it changes then just fix test.
  func test_description() {
    let storage: BigIntStorage = [1, 2, 3]
    let result = String(describing: storage)
    let expected = "BigIntStorage(isNegative: false, capacity: 3, words: [0x1, 0x10, 0x11])"
    XCTAssertEqual(result, expected)
  }
}
