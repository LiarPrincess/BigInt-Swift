// Most of the code was taken from: https://github.com/attaswift/BigInt

// MARK: - To string

extension String {

  // This may be faster than native Swift implementation.
  public init(_ value: BigInt, radix: Int = 10, uppercase: Bool = false) {
    self = value.toString(radix: radix, uppercase: uppercase)
  }
}

extension BigInt {

  private typealias Word = BigIntHeap.Word

  // MARK: - Error

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

  // MARK: - Init

  public init(_ string: String, radix: Int = 10) throws {
    let scalars = string.unicodeScalars
    let scalarsSub = scalars[...]
    try self.init(scalarsSub, radix: radix)
  }

  private init(
    _ scalars: String.UnicodeScalarView.SubSequence,
    radix: Int
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

    // Instead of using a single 'BigInt' and multipling it by 'radix',
    // we will group scalars into words-sized chunks.
    // Then we will raise those chunks to appropriate power and add together.
    //
    // For example:
    // 1_2345_6789 = (10^8 * 1) + (10^4 * 2345) + (10^0 * 6789)
    //
    // So, we are doing most of our calculations in fast 'Word',
    // and then we switch to slow BigInt for a few final operations.

    let (scalarCountPerGroup, power) = Word.maxRepresentablePower(of: radix)
    let radix = Word(radix)

    // TODO: Fast path on stack
    // Fast (on stack) path for small numbers
    // (although it can be tricked by adding '0' in front: '0000_0001' = '1').
    // Technically Swift compiler would also try to avoid heap allocations,
    // by puting things on stack, but this fast path will be taken 90% of the time,
    // so we want to be sure.
//    if scalars.count <= scalarCountPerGroup { }

    // 'groups' are in in right-to-left (lowest power first) order
    // (just as in example ablove).
    let groups = try Self.parseGroups(
      scalars: scalars,
      radix: radix,
      scalarCountPerGroup: scalarCountPerGroup
    )

    guard let mostSignificantGroup = groups.last else {
      trap("Unexpected empty groups")
    }

    // Fast path for 'Smi' (well... mostly for 'Smi')
    if groups.count == 1 {
      if let smi = mostSignificantGroup.asSmiIfPossible(isNegative: isNegative) {
        self.init(smi: smi)
        return
      }
    }

    fatalError("Not implemented")

    var result = BigIntHeap(minimumStorageCapacity: groups.count)
    result.storage[0] = mostSignificantGroup
    result.storage.isNegative = isNegative

    // 'dropLast' because we already added 'mostSignificantGroup'
    for group in groups.dropLast().reversed() {
      BigIntHeap.mulMagnitude(lhs: &result.storage, rhs: power)
      result.storage.append(group)
    }

    // TODO: fix invariants
    // TODO: Call proper 'init' when we migrate to new 'HeapStorage'
//    self.init(result)
    fatalError()
  }

  // MARK: - Groups

  /// Returns groups in right-to-left order!
  private static func parseGroups(
    scalars: String.UnicodeScalarView.SubSequence,
    radix: Word,
    scalarCountPerGroup: Int
  ) throws -> [Word] {
    var result = [Word]()

    let minimumCapacity = (scalars.count / scalarCountPerGroup) + 1
    result.reserveCapacity(minimumCapacity)

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
      // It has to be in 'else' case.
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
