import XCTest
@testable import Core

class BigIntHeapComparableTests: XCTestCase {

  // MARK: - Smi

  func test_smi_differentSign_negativeIsAlwaysLess() {
    for negativeRaw in generateSmiValues(countButNotReally: 10) {
      // '0' stays the same after negation
      if negativeRaw == 0 {
        continue
      }

      let negativeSmi = negativeRaw.isNegative ? negativeRaw : -negativeRaw
      let negativeHeap = BigIntHeap(negativeSmi)

      for positiveRaw in generateSmiValues(countButNotReally: 10) {
        // '-min' is not representable as 'Smi.Storage'
        if positiveRaw == .min {
          continue
        }

        let positive = positiveRaw.isPositive ?
          positiveRaw :
          Smi.Storage(positiveRaw.magnitude)

        XCTAssertTrue(negativeHeap < positive, "\(negativeHeap) < \(positive)")
      }
    }
  }

  func test_smi_sameSign_equalMagnitude_isNotLess() {
    for smi in generateSmiValues(countButNotReally: 100) {
      let heap = BigIntHeap(smi)
      XCTAssertFalse(heap < smi, "\(heap) < \(smi)")
    }
  }

  func test_smi_sameSign_smallerMagnitude_isLess() {
    for smi in generateSmiValues(countButNotReally: 100) {
      // '0 - 1' changes sign
      // '.min - 1' overflows
      if smi == 0 || smi == .min {
        continue
      }

      let smallerHeap = BigIntHeap(smi - 1)
      XCTAssertTrue(smallerHeap < smi, "\(smallerHeap) < \(smi)")
    }
  }

  func test_smi_sameSign_greaterMagnitude_isNeverLess() {
    for smi in generateSmiValues(countButNotReally: 100) {
      // '0 - 1' changes sign
      // '.max + 1' overflows
      if smi == 0 || smi == .max {
        continue
      }

      let biggerHeap = BigIntHeap(smi + 1)
      XCTAssertFalse(biggerHeap < smi, "\(biggerHeap) < \(smi)")
    }
  }

  func test_smi_sameSign_moreThan1Word() {
    for smi in generateSmiValues(countButNotReally: 10) {
      for heapPrototype in generateHeapValues(countButNotReally: 10) {
        // We need more words
        guard heapPrototype.words.count > 1 else {
          continue
        }

        // We need the same sign
        var heap = heapPrototype.create()
        if smi.isNegative != heap.isNegative {
          heap.negate()
        }

        // positive - more words -> bigger number
        // negative - more words -> smaller number
        if smi.isPositive {
          XCTAssertFalse(heap < smi, "\(heap) < \(smi)")
        } else {
          XCTAssertTrue(heap < smi, "\(heap) < \(smi)")
        }
      }
    }
  }
}
