import XCTest
@testable import BigInt

private typealias Storage = Smi.Storage

private let all0 = Storage(0)
private let all1 = Storage(~0)

private let max = Storage.max
private let maxHalf = max / 2
private let maxMinus1 = max - 1

private let min = Storage.min
private let minHalf = min / 2
private let minPlus1 = min + 1

class SmiShiftTests: XCTestCase {

  // MARK: - Left

  func test_left_zero() {
    self.leftWithoutOverflow(0, shift: 0)

    self.leftWithoutOverflow(1, shift: 0)
    self.leftWithoutOverflow(max, shift: 0)
    self.leftWithoutOverflow(maxHalf, shift: 0)

    self.leftWithoutOverflow(-1, shift: 0)
    self.leftWithoutOverflow(min, shift: 0)
    self.leftWithoutOverflow(minHalf, shift: 0)
  }

  func test_left_withoutOverflow() {
    func isSmi(value: Storage, shift: Int) -> Bool {
      let shifted = Int(value) << shift
      return Smi(shifted) != nil
    }

    let shiftValues = 0..<(Storage.bitWidth / 2)

    for shift in shiftValues {
      self.leftWithoutOverflow(0, shift: shift)
    }

    for (_, value) in allPositivePowersOf2(type: Storage.self) {
      for shift in shiftValues {
        guard isSmi(value: value, shift: shift) else {
          continue
        }

        self.leftWithoutOverflow(value, shift: shift)
      }
    }

    for (_, value) in allNegativePowersOf2(type: Storage.self) {
      for shift in shiftValues {
        guard isSmi(value: value, shift: shift) else {
          continue
        }

        leftWithoutOverflow(value, shift: shift)
      }
    }
  }

  private func leftWithoutOverflow<T: BinaryInteger>(_ _lhs: Storage,
                                                     shift: T,
                                                     file: StaticString = #file,
                                                     line: UInt = #line) {
    let lhs = Smi(_lhs)
    let expected = Int(_lhs) << shift
    let msg = "\(lhs) << \(shift)"

    print(bin(_lhs), "<<", shift, "=", expected, "(max: \(max))") // TODO: xxx
    let thingie = lhs.shiftLeft(count: shift)
    XCTAssert(thingie.isSmi, msg, file: file, line: line)
    XCTAssertEqual(thingie, BigInt(expected), msg, file: file, line: line)
  }
}
