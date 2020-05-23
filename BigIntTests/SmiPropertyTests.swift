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

class SmiPropertyTests: XCTestCase {

  // MARK: - Is zero

  func test_isZero() {
    self.zero(0, isZero: true)

    self.zero(-1, isZero: false)
    self.zero(1, isZero: false)

    self.zero(max, isZero: false)
    self.zero(maxHalf, isZero: false)
    self.zero(maxMinus1, isZero: false)

    self.zero(min, isZero: false)
    self.zero(minHalf, isZero: false)
    self.zero(minPlus1, isZero: false)
  }

  private func zero(_ value: Int32,
                    isZero: Bool,
                    file: StaticString = #file,
                    line: UInt = #line) {
    let smi = Smi(value)
    XCTAssertEqual(smi.isZero, isZero, file: file, line: line)
  }

  // MARK: - Is negative

  func test_isNegative() {
    self.negative(0, isNegative: false)

    self.negative(1, isNegative: false)
    self.negative(max, isNegative: false)
    self.negative(maxHalf, isNegative: false)
    self.negative(maxMinus1, isNegative: false)

    self.negative(-1, isNegative: true)
    self.negative(min, isNegative: true)
    self.negative(minHalf, isNegative: true)
    self.negative(minPlus1, isNegative: true)
  }

  private func negative(_ value: Int32,
                        isNegative: Bool,
                        file: StaticString = #file,
                        line: UInt = #line) {
    let smi = Smi(value)
    XCTAssertEqual(smi.isNegative, isNegative, file: file, line: line)
  }

  // MARK: - Min required width

  func test_minRequiredWidth() {
    self.minRequiredWidth(all0, minRequiredWidth: 0)
    self.minRequiredWidth(all1, minRequiredWidth: 1) // -1 requires 1 bit

    for (power, value) in allPositivePowersOf2(type: Storage.self) {
      // >>> for i in range(1, 10):
      // ...     value = 1 << i
      // ...     print(i, value, value.bit_length())
      // ...
      // 1 2 2
      // 2 4 3
      // 3 8 4
      // 4 16 5
      let minRequiredWidth = power + 1
      self.minRequiredWidth(value, minRequiredWidth: minRequiredWidth)
    }

    for (power, value) in allNegativePowersOf2(type: Storage.self) {
      // >>> for i in range(1, 10):
      // ...     value = 1 << i
      // ...     print(i, (-value).bit_length())
      //
      // 1 2
      // 2 3
      // 3 4
      // (etc)
      let minRequiredWidth = power + 1
      self.minRequiredWidth(value, minRequiredWidth: minRequiredWidth)
    }
  }

  private func minRequiredWidth(_ value: Int32,
                                minRequiredWidth: Int,
                                file: StaticString = #file,
                                line: UInt = #line) {
    let smi = Smi(value)
    XCTAssertEqual(smi.minRequiredWidth, minRequiredWidth, file: file, line: line)
  }
}
