import XCTest
@testable import Core

private class BigNumHeap {

  fileprivate var data: [Int]

  fileprivate init(data: [Int]) {
    self.data = data
  }
}

private struct BigNum {

  fileprivate enum Storage {
    case smi(Int32)
    case heap(BigNumHeap)
  }

  fileprivate var value: Storage

  fileprivate init(_ value: Int32) {
    self.value = .smi(value)
  }

  fileprivate init(_ value: BigNumHeap) {
    self.value = .heap(value)
  }

  fileprivate static func += (lhs: inout BigNum, rhs: BigNum) {
    switch lhs.value {
    case .smi: fatalError()
    case .heap(let h): h.data.append(666)
    }
  }
}

class InoutTests: XCTestCase {

  func test_xx() {
    let x = 10
    let y = 3

    print(" \(x) /  \(y) =", x / y, "rem:", x % y)
    print(" \(x) / -\(y) =", x / (-y), "rem:", x % (-y))
    print("-\(x) /  \(y) =", (-x) / y, "rem:", (-x) % y)
    print("-\(x) / -\(y) =", (-x) / (-y), "rem:", (-x) % (-y))
  }

  func test_xxx() {
    let heap = BigNumHeap(data: [1, 2, 3])
    var num = BigNum(heap)

    print(heap.data)
    dummyFn(&num)
    print(heap.data)

    var x = 5
    print(x)
    dummyFn(&x)
    print(x)

//    fatalError()
  }

  private func dummyFn(_ value: inout BigNum) {
    value += BigNum(15)
  }

  private func dummyFn(_ value: inout Int) {
    value += 15
  }
}
