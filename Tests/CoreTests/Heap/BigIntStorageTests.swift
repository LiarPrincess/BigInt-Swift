import XCTest
@testable import Core

private typealias Word = BigIntStorage.Word

// MARK: - Init helper

extension BigIntStorage {

  fileprivate init(isNegative: Bool, words: Word...) {
    assert(!words.isEmpty, "Use different 'init' to create zero")

    self.init(minimumCapacity: words.count)
    self.isNegative = isNegative

    for word in words {
      self.append(word)
    }
  }
}

// MARK: - BigIntStorageTests

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

  // MARK: - Properties

  func test_isNegative_cow() {
    let orginal = BigIntStorage(isNegative: false, words: 0, 1, 2)
    let orginalIsNegative = orginal.isNegative

    var copy = orginal
    copy.isNegative.toggle()

    XCTAssertEqual(orginal.isNegative, orginalIsNegative)
    XCTAssertEqual(copy.isNegative, !orginalIsNegative)
  }

  // MARK: - Subscript

  func test_subscript_get() {
    let storage = BigIntStorage(isNegative: false, words: 0, 1, 2, 3)

    for i in 0..<storage.count {
      XCTAssertEqual(storage[i], Word(i))
    }
  }

  func test_subscript_set() {
    var storage = BigIntStorage(isNegative: false, words: 0, 1, 2, 3)

    for i in 0..<storage.count {
      storage[i] += 1
      XCTAssertEqual(storage[i], Word(i + 1))
    }
  }

  func test_subscript_set_cow() {
    let orginal = BigIntStorage(isNegative: false, words: 0, 1, 2)

    var copy = orginal
    copy[0] = 100

    XCTAssertEqual(orginal.count, 3)
    XCTAssertEqual(copy.count, 3)

    for i in 0..<orginal.count {
      XCTAssertEqual(orginal[i], Word(i))

      let copyExpected = i == 0 ? 100 : i
      XCTAssertEqual(copy[i], Word(copyExpected))
    }
  }

  // MARK: - Append word

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

    // This should grow
    storage.append(100)

    XCTAssertNotEqual(storage.capacity, oldCapacity)
    XCTAssertGreaterThan(storage.capacity, oldCapacity)

    for i in 0..<oldCapacity {
      XCTAssertEqual(storage[i], Word(i))
    }
    XCTAssertEqual(storage.last, Word(100))
  }

  func test_append_cow() {
    let orginal = BigIntStorage(isNegative: false, words: 0, 1, 2)

    var copy = orginal
    copy.append(100)

    XCTAssertEqual(orginal, BigIntStorage(isNegative: false, words: 0, 1, 2))
    XCTAssertEqual(copy, BigIntStorage(isNegative: false, words: 0, 1, 2, 100))
  }

  // MARK: - Equatable

  func test_equatable() {
    let orginal = BigIntStorage(isNegative: false, words: 0, 1, 2)
    XCTAssertEqual(orginal, BigIntStorage(isNegative: false, words: 0, 1, 2))

    var negative = orginal
    negative.isNegative.toggle()
    XCTAssertNotEqual(orginal, negative)

    var withAppend = orginal
    withAppend.append(100)
    XCTAssertNotEqual(orginal, withAppend)

    var changedFirst = orginal
    changedFirst[0] = 100
    XCTAssertNotEqual(orginal, changedFirst)

    var changedLast = orginal
    changedLast[2] = 100
    XCTAssertNotEqual(orginal, changedLast)
  }

  // MARK: - Set unsigned

  private let unsignedValues: [UInt] = [103, 0, .max, .min]

  func test_set_UInt() {
    var storage = BigIntStorage(isNegative: false, words: 1, 2, 3)

    for value in self.unsignedValues {
      print(value)
      storage.set(to: value)
      XCTAssertEqual(storage, BigIntStorage(isNegative: false, magnitude: value))
    }
  }

  func test_set_UInt_cow() {
    let orginal = BigIntStorage(isNegative: true, words: 1, 2, 3)

    for value in self.unsignedValues {
      var copy = orginal
      copy.set(to: value)

      XCTAssertEqual(orginal, BigIntStorage(isNegative: false, words: 1, 2, 3))
      XCTAssertEqual(copy, BigIntStorage(isNegative: false, magnitude: value))
    }
  }

  // MARK: - Set signed

  private let signedValues: [Int] = [103, 0, -104, .max, .min]

  func test_set_Int() {
    var storage = BigIntStorage(isNegative: false, words: 1, 2, 3)

    for value in self.signedValues {
      storage.set(to: value)
      XCTAssertEqual(storage, BigIntStorage(isNegative: false, magnitude: value.magnitude))
    }
  }

  func test_set_Int_cow() {
    let orginal = BigIntStorage(isNegative: false, words: 1, 2, 3)

    for value in self.signedValues {
      var copy = orginal
      copy.set(to: value)

      XCTAssertEqual(orginal, BigIntStorage(isNegative: false, words: 1, 2, 3))
      XCTAssertEqual(copy, BigIntStorage(isNegative: false, magnitude: value.magnitude))
    }
  }

  // MARK: - Transform

  func test_transform() {
    var storage = BigIntStorage(isNegative: false, words: 1, 2, 3)
    storage.transformEveryWord { $0 + 1 }

    XCTAssertEqual(storage, BigIntStorage(isNegative: false, words: 2, 3, 4))
  }

  func test_transform_cow() {
    let orginal = BigIntStorage(isNegative: false, words: 1, 2, 3)

    var copy = orginal
    copy.transformEveryWord { $0 + 1 }

    XCTAssertEqual(orginal, BigIntStorage(isNegative: false, words: 1, 2, 3))
    XCTAssertEqual(copy, BigIntStorage(isNegative: false, words: 2, 3, 4))
  }

  // MARK: - Description

  /// Please note that `capacity` is implementation dependent,
  /// if it changes then just fix test.
  func test_description() {
    let storage = BigIntStorage(isNegative: false, words: 1, 2, 3)

    let result = String(describing: storage)
    let expected = "BigIntStorage(isNegative: false, capacity: 3, words: [0x1, 0x10, 0x11])"
    XCTAssertEqual(result, expected)
  }
}
