import XCTest
@testable import Core

// Tests taken from:
// https://github.com/benrimmington/swift-numerics/blob/BigInt/Tests/BigIntTests/BigIntTests.swift

private typealias Word = BigIntStorage.Word

class BigIntHeapFloatingPointTests: XCTestCase {

  func test_special() {
    self.testBinaryFloatingPoint(Float32.self)
    self.testBinaryFloatingPoint(Float64.self)
  }

  private func testBinaryFloatingPoint<T: BinaryFloatingPoint>(_ type: T.Type) {
    let zero = BigIntHeap(0)

    // TODO: Uncomment this when we have bit operations
/*
    var expected = BigIntHeapNew(T.greatestFiniteMagnitude.significandBitPattern)
    expected |= BigIntHeapNew(1) << T.significandBitCount
    expected <<= T.greatestFiniteMagnitude.exponent
    expected >>= T.significandBitCount

    XCTAssertEqual(BigIntHeapNew(exactly: -T.greatestFiniteMagnitude), -expected)
    XCTAssertEqual(BigIntHeapNew(exactly: +T.greatestFiniteMagnitude), +expected)
    XCTAssertEqual(BigIntHeapNew(-T.greatestFiniteMagnitude), -expected)
    XCTAssertEqual(BigIntHeapNew(+T.greatestFiniteMagnitude), +expected)
*/

    XCTAssertNil(BigIntHeap(exactly: -T.infinity))
    XCTAssertNil(BigIntHeap(exactly: +T.infinity))

    XCTAssertNil(BigIntHeap(exactly: -T.leastNonzeroMagnitude))
    XCTAssertNil(BigIntHeap(exactly: +T.leastNonzeroMagnitude))
    XCTAssertEqual(BigIntHeap(-T.leastNonzeroMagnitude), zero)
    XCTAssertEqual(BigIntHeap(+T.leastNonzeroMagnitude), zero)

    XCTAssertNil(BigIntHeap(exactly: -T.leastNormalMagnitude))
    XCTAssertNil(BigIntHeap(exactly: +T.leastNormalMagnitude))
    XCTAssertEqual(BigIntHeap(-T.leastNormalMagnitude), zero)
    XCTAssertEqual(BigIntHeap(+T.leastNormalMagnitude), zero)

    XCTAssertNil(BigIntHeap(exactly: T.nan))
    XCTAssertNil(BigIntHeap(exactly: T.signalingNaN))

    XCTAssertNil(BigIntHeap(exactly: -T.pi))
    XCTAssertNil(BigIntHeap(exactly: +T.pi))
    XCTAssertEqual(BigIntHeap(-T.pi), BigIntHeap(-3))
    XCTAssertEqual(BigIntHeap(+T.pi), BigIntHeap(3))

    XCTAssertNil(BigIntHeap(exactly: -T.ulpOfOne))
    XCTAssertNil(BigIntHeap(exactly: +T.ulpOfOne))
    XCTAssertEqual(BigIntHeap(-T.ulpOfOne), zero)
    XCTAssertEqual(BigIntHeap(+T.ulpOfOne), zero)

    XCTAssertEqual(BigIntHeap(exactly: -T.zero), zero)
    XCTAssertEqual(BigIntHeap(exactly: +T.zero), zero)
    XCTAssertEqual(BigIntHeap(-T.zero), zero)
    XCTAssertEqual(BigIntHeap(+T.zero), zero)
  }

  func test_random() {
    for _ in 0 ..< 100 {
      let small = Float32.random(in: -10 ... +10)
      XCTAssertEqual(BigIntHeap(small), BigIntHeap(Int64(small)))

      let large = Float32.random(in: -0x1p23 ... +0x1p23)
      XCTAssertEqual(BigIntHeap(large), BigIntHeap(Int64(large)))
    }

    for _ in 0 ..< 100 {
      let small = Float64.random(in: -10 ... +10)
      XCTAssertEqual(BigIntHeap(small), BigIntHeap(Int64(small)))

      let large = Float64.random(in: -0x1p52 ... +0x1p52)
      XCTAssertEqual(BigIntHeap(large), BigIntHeap(Int64(large)))
    }
  }
}