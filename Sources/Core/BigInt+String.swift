// Most of the code was taken from: https://github.com/attaswift/BigInt

// MARK: - To string

extension String {

  // This may be faster than native Swift implementation.
  public init(_ value: BigInt, radix: Int = 10, uppercase: Bool = false) {
    self = value.toString(radix: radix, uppercase: uppercase)
  }
}

// MARK: - Init

extension BigInt {

  internal typealias Word = BigIntHeap.Word

  public enum ParsingError: Error {
    /// String is empty
    case emptyString
    /// String contains '__'
    case doubleUnderscore
    /// String starts with '_'
    case prefixUnderscore
    /// String ends with '_'
    case suffixUnderscore
    /// Digit is not valid for given prefix
    case notDigit(UnicodeScalar)
  }

  public init(
    _ scalars: String.UnicodeScalarView.SubSequence,
    radix: Int = 10
  ) throws {
    precondition(2 <= radix && radix <= 36, "Radix not in range 2...36.")

    // This will also handle empty string
    guard let first = scalars.first else {
      throw ParsingError.emptyString
    }

    var scalars = scalars

    var isNegative = false
    if first == "+" {
      scalars = scalars.dropFirst()
    } else if first == "-" {
      scalars = scalars.dropFirst()
      isNegative = true
    }

    // Instead of using a single 'BigInt' and multipling it by 10,
    // we will group scalars into words-sized chunks.
    // Then we will raise those chunks to appropriate power and add together.
    //
    // For example:
    // 1_2345_6789 = (10^8 * 1) + (10^4 * 2345) + (10^0 * 6789)
    //
    // So, we are doing most of our calculations in fast 'UInt',
    // and then we switch to slow BigInt for a few final operations.

    let (scalarCountPerGroup, power) = Self.scalarsPerWord(radix: radix)
    let radix = Word(radix)

    // 'groups' are in right-to-left order!
    let groups = try Self.parseGroups(
      scalars: scalars,
      radix: radix,
      scalarCountPerGroup: scalarCountPerGroup
    )

    // TODO: Fast path for 'Smi' (without allocation)
    // groups.fixInvariants()
    // Remember sign!

    var result = BigIntHeap(minimumStorageCapacity: groups.count)
    result.storage.isNegative = isNegative

    for group in groups.reversed() {
      BigIntHeap.mulMagnitude(lhs: &result.storage, rhs: power)
      result.storage.append(group)
    }

    // TODO: Call proper 'init' when we migrate to new 'HeapStorage'
//    self.init(result)
    fatalError()
  }

  /// Calculates the number of scalars that fits inside a single `Word`
  /// (for a given `radix`).
  ///
  /// Returns the highest number that satisfy `radix^count <= 2^Word.bitWidth`
  ///
  /// `charsPerWord` in `attaswift/BigInt`.
  internal static func scalarsPerWord(radix: Int) -> (count: Int, power: Word) {
    var power: Word = 1
    var overflow = false
    var count = 0

    while !overflow {
      let (p, o) = power.multipliedReportingOverflow(by: Word(radix))
      overflow = o

      if !o || p == 0 {
        count += 1
        power = p
      }
    }

    return (count, power)
  }

  /// Returns groups in right-to-left order!
  private static func parseGroups(
    scalars: String.UnicodeScalarView.SubSequence,
    radix: Word,
    scalarCountPerGroup: Int
  ) throws -> BigIntStorage {
    let resultCount = (scalars.count / scalarCountPerGroup) + 1
    var result = BigIntStorage(minimumCapacity: resultCount)

    // Group that we are currently working on, it will be added to 'result' later
    var currentGroup = Word.zero

    // Prevent '__' (but single '_' is ok)
    var isPreviousUnderscore = false

    // `group = (power^2 * digit) + (power^1 * digit) + (power^0 * digit)` etc.
    var power = Word(1)

    // Note that the 'index' is from the end on the string
    for (index, scalar) in scalars.reversed().enumerated() {
      let isUnderscore = scalar == "_"
      defer { isPreviousUnderscore = isUnderscore }

      if isUnderscore {
        // Those names are correct! Remember that we are going 'in reverse'!
        let isFirst = index == scalars.count - 1
        let isLast = index == 0

        if isPreviousUnderscore { throw ParsingError.doubleUnderscore }
        if isFirst { throw ParsingError.prefixUnderscore }
        if isLast { throw ParsingError.suffixUnderscore }
        continue // Skip underscores
      }

      guard let digit = scalar.asDigit, digit < radix else {
        throw ParsingError.notDigit(scalar)
      }

      // Prefix 'currentGroup' with current digit
      currentGroup = power * digit + currentGroup
      // Do not move 'power *= radix' here, because it will overflow!

      let isLastInGroup = (index + 1).isMultiple(of: scalarCountPerGroup)
      if isLastInGroup {
        result.append(currentGroup)
        currentGroup = 0
        power = 1
      } else {
        power *= radix
      }
    }

    result.append(currentGroup)
    return result
  }
}
