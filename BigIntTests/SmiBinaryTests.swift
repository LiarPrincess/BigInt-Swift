import XCTest
@testable import BigInt

private typealias Storage = Smi.Storage

private let max = Storage.max
private let maxHalf = max / 2
private let maxMinus1 = max - 1

private let min = Storage.min
private let minHalf = min / 2
private let minPlus1 = min + 1

class SmiBinaryTests: XCTestCase {

  // MARK: - Add

  func test_add_withoutOverflow() {
    // Zero
    self.addWithoutOverflow(0, 1, expecting: 1)
    self.addWithoutOverflow(0, -1, expecting: -1)

    // Crossing 0
    self.addWithoutOverflow(-1, 2, expecting: 1)
    self.addWithoutOverflow(1, -2, expecting: -1)

    // Min max
    self.addWithoutOverflow(max, 0, expecting: max)
    self.addWithoutOverflow(min, 0, expecting: min)
    self.addWithoutOverflow(max, min, expecting: -1)
    self.addWithoutOverflow(maxMinus1, 1, expecting: max)
    self.addWithoutOverflow(minPlus1, -1, expecting: min)
  }

  private func addWithoutOverflow(_ lhs: Int32,
                                  _ rhs: Int32,
                                  expecting: Int32,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
    let lhs = Smi(lhs)
    let rhs = Smi(rhs)
    let expected = BigInt(smi: expecting)

    let lhsAdd = lhs.add(other: rhs)
    XCTAssert(lhsAdd.isSmi, file: file, line: line)
    XCTAssertEqual(lhsAdd, expected, file: file, line: line)

    let rhsAdd = rhs.add(other: lhs)
    XCTAssert(rhsAdd.isSmi, file: file, line: line)
    XCTAssertEqual(rhsAdd, expected, file: file, line: line)
  }

  func test_add_overflow_positive() {
    self.addWithOverflow(max, 1, expecting: Int(max) + 1)
    self.addWithOverflow(max, max, expecting: Int(max) + Int(max))
    self.addWithOverflow(max, maxMinus1, expecting: Int(max) + Int(maxMinus1))
    self.addWithOverflow(maxHalf, max, expecting: Int(maxHalf) + Int(max))

    let testCount = Storage(128)
    let step = max / testCount

    for i in 1..<testCount {
      let other = i * step
      let expected = Int(max) + Int(other)
      self.addWithOverflow(max, other, expecting: expected)
    }
  }

  func test_add_overflow_negative() {
//    self.addWithOverflow(min, -1, expecting: Int(min) - 1)
    self.addWithOverflow(min, min, expecting: Int(min) + Int(min))
    self.addWithOverflow(min, minPlus1, expecting: Int(min) + Int(minPlus1))
    self.addWithOverflow(minHalf, min, expecting: Int(minHalf) + Int(min))

    let testCount = Storage(128)
    let step = max / testCount

    for i in 1..<testCount {
      let other = -i * step
      let expected = Int(min) + Int(other)
      self.addWithOverflow(min, other, expecting: expected)
    }
  }

  private func addWithOverflow(_ lhs: Int32,
                               _ rhs: Int32,
                               expecting: Int,
                               file: StaticString = #file,
                               line: UInt = #line) {
    let lhs = Smi(lhs)
    let rhs = Smi(rhs)
    let expected = BigInt(expecting)

    let lhsAdd = lhs.add(other: rhs)
    XCTAssert(lhsAdd.isHeap, file: file, line: line)
    XCTAssertEqual(lhsAdd, expected, file: file, line: line)

    let rhsAdd = rhs.add(other: lhs)
    XCTAssert(rhsAdd.isHeap, file: file, line: line)
    XCTAssertEqual(rhsAdd, expected, file: file, line: line)
  }
}
