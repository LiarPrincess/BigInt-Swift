extension BigIntHeap {

  // MARK: - Left

  internal mutating func shiftLeft(count: Smi.Storage) {
    let word = Word(count.magnitude)

    if count.isPositive {
      self.shiftLeft(count: word)
    } else {
      self.shiftRight(count: word)
    }
  }

  internal mutating func shiftLeft(count: Word) {
    defer { self.checkInvariants() }

    if self.isZero || count.isZero {
      return
    }

    let wordShift = Int(count / Word(Word.bitWidth))
    let bitShift = Int(count % Word(Word.bitWidth))

    self.storage.prepend(0, repeated: wordShift)

    if bitShift == 0 {
      return
    }

    // Ok, now we have to deal with bit (subword) shifting.
    // We will always start from the end to avoid overwriting lower words,
    // this is why we will use 'reversed'.
    //
    // Example for '1011 << 5' (assuming that our Word has 4 bits):
    // - Expected result:
    //   [1011] << 5 = [0001][0110][0000]
    //   But because we store 'low' words before 'high' words in our storage,
    //   this will be stored as [0000][0110][0001].
    // - Current situation:
    //   [1011] << 4 (because our Word has 4 bits) = [1011][0000]
    //   Which is stored as: [0000][1011]
    // - To be done:
    //   Shift by this 1 bit, because 4 (our Word size) + 1 = 5 (requested shift)

    // Append word that will be used for shifts from our most significant word.
    self.storage.append(0) // In example: [0000][1011][0000]

    let lowShift = bitShift // In example: 5 % 4 = 1
    let highShift = Word.bitWidth - lowShift // In example: 4 - 1 = 3

    for i in (0..<self.storage.count).reversed() {
      let indexAfterWordShift = i + wordShift

      let word = self.storage[indexAfterWordShift] // In example: [1011]
      let lowPart = word << lowShift               // In example: [1011] << 1 = [0110]
      let highPart = word >> highShift             // In example: [1011] >> 3 = [0001]

      let lowIndex = indexAfterWordShift // In example: 1 + 0 = 1, [0000][this][0000]
      let highIndex = lowIndex + 1       // In example: 1 + 1 = 2, [0000][1011][this]

      self.storage[lowIndex] = lowPart
      self.storage[highIndex] = self.storage[highIndex] | highPart
    }

    self.fixInvariants()
  }

  internal mutating func shiftLeft(count: BigIntHeap) {
    defer { self.checkInvariants() }

    if count.isPositive {
      guard let word = self.guaranteeSingleWord(shiftCount: count) else {
        // Something is off.
        // We will execute order 66 and kill the jedi before they take control
        // over the whole galaxy (also known as ENOMEM).
        let msg = "Shifting by more than \(Word.max) is not possible "
                + "(and it is probably not what you want anyway, "
                + "do you really have that much memory?)."
        trap(msg)
      }

      self.shiftLeft(count: word)
    } else {
      guard let word = self.guaranteeSingleWord(shiftCount: count) else {
        self.storage.setToZero()
        return
      }

      self.shiftRight(count: word)
    }
  }

  // MARK: - Right

  internal mutating func shiftRight(count: Smi.Storage) {
    let word = Word(count.magnitude)

    if count.isPositive {
      self.shiftRight(count: word)
    } else {
      self.shiftLeft(count: word)
    }
  }

  internal mutating func shiftRight(count: Word) {
    if count.isZero {
      return
    }

    // TODO: if count > bitWidth -> 0
    fatalError()
  }

  // MARK: - Reasonable count

  private func guaranteeSingleWord(shiftCount: BigIntHeap) -> Word? {
    guard shiftCount.storage.count == 1 else {
      return nil
    }

    return shiftCount.storage[0]
  }
}
