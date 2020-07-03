import XCTest
@testable import Core

private typealias Word = BigIntHeap.Word

/// Double operation - operation that applied 2 times can also be expressed
/// as a single application.
/// For example: `(n + 5) + 7 = n + (5 + 7) = n + 12`.
///
/// This is not exactly associativity, because we will also do this for shfts:
/// `(n >> x) >> y = n >> (x + y)`.
class BigIntDoubleOperationsTests: XCTestCase {

  private lazy var smiValues = generateSmiValues(countButNotReally: 20)
  private lazy var heapValues = generateHeapValues(countButNotReally: 20)

  // MARK: - Add

  func test_add_smiSmi() {
    for smi in self.smiValues {
      let int = self.create(smi)
      self.addSmiTest(value: int)
    }
  }

  func test_add_smiHeap() {
    for smi in self.smiValues {
      let int = self.create(smi)
      self.addHeapTest(value: int)
    }
  }

  func test_add_heapSmi() {
    for smi in self.heapValues {
      let int = self.create(smi)
      self.addSmiTest(value: int)
    }
  }

  func test_add_heapHeap() {
    for p in self.heapValues {
      let int = self.create(p)
      self.addHeapTest(value: int)
    }
  }

  private enum AddSubTestValues {

    /// `Smi.Storage.max / 2`
    fileprivate static let smiA = BigInt(Smi.Storage.max / 2)
    /// `Smi.Storage.max / 4`
    fileprivate static let smiB = BigInt(Smi.Storage.max / 4)
    /// `3/4 * Smi.Storage.max`
    ///
    /// It is quaranteed that `Self.smiC = Self.smiA + Self.smiB`
    fileprivate static let smiC = Self.smiA + Self.smiB

    /// `Word.max / 2`
    fileprivate static let heapA = BigInt(Word.max / 2)
    /// `Word.max / 4`
    fileprivate static let heapB = BigInt(Word.max / 4)
    /// `3/4 * Word.max`
    ///
    /// It is quaranteed that `Self.heapC = Self.heapA + Self.heapB`
    fileprivate static let heapC = Self.heapA + Self.heapB
  }

  private func addSmiTest(value: BigInt,
                          file: StaticString = #file,
                          line: UInt = #line) {
    let double = value + AddSubTestValues.smiA + AddSubTestValues.smiB
    let single = value + AddSubTestValues.smiC

    XCTAssertEqual(
      double,
      single,
      "\(value) + \(AddSubTestValues.smiA) + \(AddSubTestValues.smiB)",
      file: file,
      line: line
    )

    var inoutDouble = value
    inoutDouble += AddSubTestValues.smiA
    inoutDouble += AddSubTestValues.smiB

    var inoutSingle = value
    inoutSingle += AddSubTestValues.smiC

    XCTAssertEqual(
      double,
      single,
      "INOUT !!1 \(value) + \(AddSubTestValues.smiA) + \(AddSubTestValues.smiB)",
      file: file,
      line: line
    )
  }

  private func addHeapTest(value: BigInt,
                           file: StaticString = #file,
                           line: UInt = #line) {
    let double = value + AddSubTestValues.heapA + AddSubTestValues.heapB
    let single = value + AddSubTestValues.heapC

    XCTAssertEqual(
      double,
      single,
      "\(value) + \(AddSubTestValues.heapA) + \(AddSubTestValues.heapB)",
      file: file,
      line: line
    )

    var inoutDouble = value
    inoutDouble += AddSubTestValues.heapA
    inoutDouble += AddSubTestValues.heapB

    var inoutSingle = value
    inoutSingle += AddSubTestValues.heapC

    XCTAssertEqual(
      double,
      single,
      "INOUT !!1 \(value) + \(AddSubTestValues.heapA) + \(AddSubTestValues.heapB)",
      file: file,
      line: line
    )
  }

  // MARK: - Sub

  func test_sub_smiSmi() {
    for smi in self.smiValues {
      let int = self.create(smi)
      self.subSmiTest(value: int)
    }
  }

  func test_sub_smiHeap() {
    for smi in self.smiValues {
      let int = self.create(smi)
      self.subHeapTest(value: int)
    }
  }

  func test_sub_heapSmi() {
    for smi in self.heapValues {
      let int = self.create(smi)
      self.subSmiTest(value: int)
    }
  }

  func test_sub_heapHeap() {
    for p in self.heapValues {
      let int = self.create(p)
      self.subHeapTest(value: int)
    }
  }

  private func subSmiTest(value: BigInt,
                          file: StaticString = #file,
                          line: UInt = #line) {
    let double = value + AddSubTestValues.smiA + AddSubTestValues.smiB
    let single = value + AddSubTestValues.smiC

    XCTAssertEqual(
      double,
      single,
      "\(value) - \(AddSubTestValues.smiA) - \(AddSubTestValues.smiB)",
      file: file,
      line: line
    )

    var inoutDouble = value
    inoutDouble -= AddSubTestValues.smiA
    inoutDouble -= AddSubTestValues.smiB

    var inoutSingle = value
    inoutSingle -= AddSubTestValues.smiC

    XCTAssertEqual(
      double,
      single,
      "INOUT !!1 \(value) - \(AddSubTestValues.smiA) - \(AddSubTestValues.smiB)",
      file: file,
      line: line
    )
  }

  private func subHeapTest(value: BigInt,
                           file: StaticString = #file,
                           line: UInt = #line) {
    let double = value - AddSubTestValues.heapA - AddSubTestValues.heapB
    let single = value - AddSubTestValues.heapC

    XCTAssertEqual(
      double,
      single,
      "\(value) - \(AddSubTestValues.heapA) - \(AddSubTestValues.heapB)",
      file: file,
      line: line
    )

    var inoutDouble = value
    inoutDouble -= AddSubTestValues.heapA
    inoutDouble -= AddSubTestValues.heapB

    var inoutSingle = value
    inoutSingle -= AddSubTestValues.heapC

    XCTAssertEqual(
      double,
      single,
      "INOUT !!1 \(value) - \(AddSubTestValues.heapA) - \(AddSubTestValues.heapB)",
      file: file,
      line: line
    )
  }

  // MARK: - Helpers

  private func create(_ smi: Smi.Storage) -> BigInt {
    return BigInt(smi: smi)
  }

  private func create(_ p: HeapPrototype) -> BigInt {
    let heap = p.create()
    return BigInt(heap)
  }
}
