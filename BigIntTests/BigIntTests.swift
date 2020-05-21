import XCTest
@testable import BigInt

class BigIntTests: XCTestCase {

  func test_size() {
    XCTAssertEqual(MemoryLayout<BigInt>.size, 8)
    XCTAssertEqual(MemoryLayout<BigInt>.stride, 8)
  }
}
