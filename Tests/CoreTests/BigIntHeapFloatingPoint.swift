import XCTest
@testable import Core

// Tests taken from:
// https://github.com/benrimmington/swift-numerics/blob/BigInt/Tests/BigIntTests/BigIntTests.swift

private typealias Word = BigIntStorage.Word

class BigIntHeapFloatingPoint: XCTestCase {

  func test_special() {
    self.testBinaryFloatingPoint(Float32.self)
    self.testBinaryFloatingPoint(Float64.self)
  }

  private func testBinaryFloatingPoint<T: BinaryFloatingPoint>(_ type: T.Type) {
    // TODO: Uncomment this when we have shifts
//    var expected = BigIntHeapNew(T.greatestFiniteMagnitude.significandBitPattern)
//    expected |= BigIntHeapNew(1) << T.significandBitCount
//    expected <<= T.greatestFiniteMagnitude.exponent
//    expected >>= T.significandBitCount

//    XCTAssertEqual(BigIntHeapNew(exactly: -T.greatestFiniteMagnitude), -expected)
//    XCTAssertEqual(BigIntHeapNew(exactly: +T.greatestFiniteMagnitude), +expected)
//    XCTAssertEqual(BigIntHeapNew(-T.greatestFiniteMagnitude), -expected)
//    XCTAssertEqual(BigIntHeapNew(+T.greatestFiniteMagnitude), +expected)

    XCTAssertNil(BigIntHeapNew(exactly: -T.infinity))
    XCTAssertNil(BigIntHeapNew(exactly: +T.infinity))

    XCTAssertNil(BigIntHeapNew(exactly: -T.leastNonzeroMagnitude))
    XCTAssertNil(BigIntHeapNew(exactly: +T.leastNonzeroMagnitude))
    XCTAssertEqual(BigIntHeapNew(-T.leastNonzeroMagnitude), 0)
    XCTAssertEqual(BigIntHeapNew(+T.leastNonzeroMagnitude), 0)

    XCTAssertNil(BigIntHeapNew(exactly: -T.leastNormalMagnitude))
    XCTAssertNil(BigIntHeapNew(exactly: +T.leastNormalMagnitude))
    XCTAssertEqual(BigIntHeapNew(-T.leastNormalMagnitude), 0)
    XCTAssertEqual(BigIntHeapNew(+T.leastNormalMagnitude), 0)

    XCTAssertNil(BigIntHeapNew(exactly: T.nan))
    XCTAssertNil(BigIntHeapNew(exactly: T.signalingNaN))

    XCTAssertNil(BigIntHeapNew(exactly: -T.pi))
    XCTAssertNil(BigIntHeapNew(exactly: +T.pi))
    XCTAssertEqual(BigIntHeapNew(-T.pi), -3)
    XCTAssertEqual(BigIntHeapNew(+T.pi), 3)

    XCTAssertNil(BigIntHeapNew(exactly: -T.ulpOfOne))
    XCTAssertNil(BigIntHeapNew(exactly: +T.ulpOfOne))
    XCTAssertEqual(BigIntHeapNew(-T.ulpOfOne), 0)
    XCTAssertEqual(BigIntHeapNew(+T.ulpOfOne), 0)

    XCTAssertEqual(BigIntHeapNew(exactly: -T.zero), 0)
    XCTAssertEqual(BigIntHeapNew(exactly: +T.zero), 0)
    XCTAssertEqual(BigIntHeapNew(-T.zero), 0)
    XCTAssertEqual(BigIntHeapNew(+T.zero), 0)
  }

  func test_random() {
    for _ in 0 ..< 100 {
      let small = Float32.random(in: -10 ... +10)
      XCTAssertEqual(BigIntHeapNew(small), BigIntHeapNew(Int64(small)))

      let large = Float32.random(in: -0x1p23 ... +0x1p23)
      XCTAssertEqual(BigIntHeapNew(large), BigIntHeapNew(Int64(large)))
    }

    for _ in 0 ..< 100 {
      let small = Float64.random(in: -10 ... +10)
      XCTAssertEqual(BigIntHeapNew(small), BigIntHeapNew(Int64(small)))

      let large = Float64.random(in: -0x1p52 ... +0x1p52)
      XCTAssertEqual(BigIntHeapNew(large), BigIntHeapNew(Int64(large)))
    }
  }
}
