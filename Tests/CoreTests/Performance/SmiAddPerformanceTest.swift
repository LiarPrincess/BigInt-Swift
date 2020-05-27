import XCTest
@testable import Core

class SmiAddPerformanceTest: XCTestCase {

  private let values: [Int32] = {
    let count = 128 * 1_024
    var result = [Int32](repeating: 0, count: count)

    let range = Int32.min...Int32.max
    for i in 0..<count {
      result[i] = Int32.random(in: range)
    }

    return result
  }()

  /*
  func test_old() {
    self.measure {
      for (lhs32, rhs32) in zip(self.values, self.values.reversed()) {
        let lhs = Smi(lhs32)
        let rhs = Smi(rhs32)
        let result = lhs.add(other: rhs)

        let expected = Int(lhs32) + Int(rhs32)
        assert(result == BigInt(expected))
      }
    }
  }

  func test_new() {
    self.measure {
      for (lhs32, rhs32) in zip(self.values, self.values.reversed()) {
        let lhs = Smi(lhs32)
        let rhs = Smi(rhs32)
        let result = lhs.add2(other: rhs)

        let expected = Int(lhs32) + Int(rhs32)
        assert(result == BigInt(expected))
      }
    }
  }
*/
}
