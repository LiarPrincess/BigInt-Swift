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
    let smallInts: [Int32] = [-2, -1, 0, 1, 2]
    for (lhs, rhs) in zip(smallInts, smallInts) {
      self.addWithoutOverflow(lhs, rhs)
    }

    // 'expecting' argument is for readers, so we know what we testing
    self.addWithoutOverflow(max, 0, expecting: max)
    self.addWithoutOverflow(min, 0, expecting: min)
    self.addWithoutOverflow(max, min, expecting: -1)

    self.addWithoutOverflow(maxMinus1, 1, expecting: max)
    self.addWithoutOverflow(minPlus1, -1, expecting: min)
  }

  private func addWithoutOverflow(_ _lhs: Int32,
                                  _ _rhs: Int32,
                                  expecting: Int32? = nil,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
    let lhs = Smi(_lhs)
    let rhs = Smi(_rhs)
    let expected = expecting.map(BigInt.init(smi:)) ?? BigInt(Int(_lhs) + Int(_rhs))
    let msg = "\(lhs) + \(rhs)"

    let lThingie = lhs.add(other: rhs)
    XCTAssert(lThingie.isSmi, msg, file: file, line: line)
    XCTAssertEqual(lThingie, expected, msg, file: file, line: line)

    let rThingie = rhs.add(other: lhs)
    XCTAssert(rThingie.isSmi, msg, file: file, line: line)
    XCTAssertEqual(rThingie, expected, msg, file: file, line: line)
  }

  func test_add_overflow_positive() {
    self.addWithOverflow(max, 1)
    self.addWithOverflow(max, max)
    self.addWithOverflow(max, maxMinus1)
    self.addWithOverflow(maxHalf, max)

    let testCount = Storage(128)
    let step = max / testCount

    for i in 1..<testCount {
      let other = i * step
      self.addWithOverflow(max, other)
    }
  }

  func test_add_overflow_negative() {
    self.addWithOverflow(min, -1)
    self.addWithOverflow(min, min)
    self.addWithOverflow(min, minPlus1)
    self.addWithOverflow(minHalf, min)

    let testCount = Storage(128)
    let step = max / testCount

    for i in 1..<testCount {
      let other = -i * step
      self.addWithOverflow(min, other)
    }
  }

  private func addWithOverflow(_ _lhs: Int32,
                               _ _rhs: Int32,
                               file: StaticString = #file,
                               line: UInt = #line) {
    let lhs = Smi(_lhs)
    let rhs = Smi(_rhs)
    let expected = BigInt(Int(_lhs) + Int(_rhs))
    let msg = "\(lhs) + \(rhs)"

    let lThingie = lhs.add(other: rhs)
    XCTAssert(lThingie.isHeap, msg, file: file, line: line)
    XCTAssertEqual(lThingie, expected, msg, file: file, line: line)

    let rThingie = rhs.add(other: lhs)
    XCTAssert(rThingie.isHeap, msg, file: file, line: line)
    XCTAssertEqual(rThingie, expected, msg, file: file, line: line)
  }

  // MARK: - Sub

  func test_sub_withoutOverflow() {
    let smallInts: [Int32] = [-2, -1, 0, 1, 2]
    for (lhs, rhs) in zip(smallInts, smallInts) {
      self.subWithoutOverflow(lhs, rhs)
    }

    // 'expecting' argument is for readers, so we know what we testing
    self.subWithoutOverflow(max, 0, expecting: max)
    self.subWithoutOverflow(min, 0, expecting: min)
    self.subWithoutOverflow(0, max, expecting: minPlus1)
    self.subWithoutOverflow(0, minPlus1, expecting: max)

    self.subWithoutOverflow(max, max, expecting: 0)
    self.subWithoutOverflow(min, min, expecting: 0)

    self.subWithoutOverflow(max, 1, expecting: maxMinus1)
    self.subWithoutOverflow(min, -1, expecting: minPlus1)

    self.subWithoutOverflow(maxMinus1, -1, expecting: max)
    self.subWithoutOverflow(minPlus1, 1, expecting: min)
    self.subWithoutOverflow(1, min + 2, expecting: max)
    self.subWithoutOverflow(-1, max, expecting: min)
  }

  private func subWithoutOverflow(_ _lhs: Int32,
                                  _ _rhs: Int32,
                                  expecting: Int32? = nil,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
    let lhs = Smi(_lhs)
    let rhs = Smi(_rhs)
    let expected = expecting.map(BigInt.init(smi:)) ?? BigInt(Int(_lhs) - Int(_rhs))
    let msg = "\(lhs) + \(rhs)"

    let thingie = lhs.sub(other: rhs)
    XCTAssert(thingie.isSmi, msg, file: file, line: line)
    XCTAssertEqual(thingie, expected, msg, file: file, line: line)
  }

  func test_sub_overflow_positive() {
    self.subWithOverflow(max, -1)
    self.subWithOverflow(max, min)
    self.subWithOverflow(max, minPlus1)
    self.subWithOverflow(maxHalf, min)

    let testCount = Storage(128)
    let step = max / testCount

    for i in 1..<testCount {
      let other = -i * step
      self.subWithOverflow(max, other)
    }
  }

  func test_sub_overflow_negative() {
    self.subWithOverflow(min, 1)
    self.subWithOverflow(min, max)
    self.subWithOverflow(min, maxMinus1)
    self.subWithOverflow(minHalf, max)

    let testCount = Storage(128)
    let step = max / testCount

    for i in 1..<testCount {
      let other = i * step
      self.subWithOverflow(min, other)
    }
  }

  private func subWithOverflow(_ _lhs: Int32,
                               _ _rhs: Int32,
                               file: StaticString = #file,
                               line: UInt = #line) {
    let lhs = Smi(_lhs)
    let rhs = Smi(_rhs)
    let expected = BigInt(Int(_lhs) - Int(_rhs))
    let msg = "\(lhs) + \(rhs)"

    let thingie = lhs.sub(other: rhs)
    XCTAssert(thingie.isHeap, msg, file: file, line: line)
    XCTAssertEqual(thingie, expected, msg, file: file, line: line)
  }
}
