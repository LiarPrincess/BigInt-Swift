internal func createAllPossiblePairVariants<T>(values: [T]) -> [(T, T)] {
  var result = [(T, T)]()

  for lhs in values {
    for rhs in values {
      let pair = (lhs, rhs)
      result.append(pair)
    }
  }

  return result
}
