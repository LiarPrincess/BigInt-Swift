import XCTest
import BigIntProxy
@testable import Core

internal func attaInt(isNegative: Bool,
                      words: [BigIntStorage.Word]) -> BigIntProxy {
  let sign: BigIntProxy.Sign = isNegative ? .minus : .plus
  let magnitude = BigUIntProxy(words: words)
  return BigIntProxy(sign: sign, magnitude: magnitude)
}

internal func attaInt(heap: BigIntHeap) -> BigIntProxy {
  let words = Array(heap.storage)
  return attaInt(isNegative: heap.isNegative, words: words)
}
