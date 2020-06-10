// Most of the code was taken from: https://github.com/attaswift/BigInt

extension BigIntHeap: CustomStringConvertible {

  internal var description: String {
    return self.toString(radix: 10, uppercase: false)
  }

  internal func toString(radix: Int, uppercase: Bool) -> String {
    precondition(2 <= radix && radix <= 36, "Radix not in range 2...36.")

    if self.isZero {
      return "0"
    }

    let sign = self.isNegative ? "-" : ""

    if self.storage.count == 1 {
      let word = self.storage[0]
      return sign + String(word, radix: radix, uppercase: uppercase)
    }

    let (scalarCountPerWord, power) = BigInt.scalarsPerWord(radix: radix)

    var parts: [String]
    if power == 0 {
      parts = self.storage.map { String($0, radix: radix, uppercase: uppercase) }
    } else {
      parts = []
      var rest = self
      if rest.isNegative {
        rest.negate()
      }

      while !rest.isZero {
        let remainder = rest.div(other: power)
        assert(remainder.isPositive)
        parts.append(String(remainder.magnitude, radix: radix, uppercase: uppercase))
      }
    }

    assert(!parts.isEmpty)

    var result = sign
    for (index, part) in parts.reversed().enumerated() {
      // Insert leading zeroes for mid-Words
      if index != 0 {
        let count = scalarCountPerWord - part.count
        assert(count >= 0) // swiftlint:disable:this empty_count
        result.append(String(repeating: "0", count: count))
      }

      result.append(part)
    }

    return result
  }
}
