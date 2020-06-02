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

    // Create space so we can shift
    self.prependZerosForShiftLeft(shiftCount: count)

    // We will always start shifting from the end to avoid overwriting lower words,
    // this is why we will use 'reversed'.
    let wordShift = Int(count / Word(Word.bitWidth))
    let bitShift = Int(count % Word(Word.bitWidth))

    if bitShift == 0 {
      // Fast path: we can just shift by whole words
      for i in (0..<self.storage.count).reversed() {
        let targetIndex = wordShift + i
        self.storage[targetIndex] = self.storage[i]
        self.storage[i] = 0
      }
    } else {
      // Slow path: we have to deal with word shift and bit (subword) shift.
      //
      // Example for '1011 << 5' (assuming that our Word has 4 bits):
      // [1011] << 5 = [0001][0110][0000]
      // But because we store 'low' words before 'high' words in our storage,
      // this will be saved as [0000][0110][0001].

      let lowShift = bitShift // In example: 5 % 4 = 1
      let highShift = Word.bitWidth - lowShift // In example: 4 - 1 = 3

      for i in (0..<self.storage.count).reversed() {
        let word = self.storage[i]       // In example: [1011]
        let lowPart = word << lowShift   // In example: [1011] << 1 = [0110]
        let highPart = word >> highShift // In example: [1011] >> 3 = [0001]

        let lowIndex = wordShift + i // In example: 1 + 0 = 1, [0000][this][0001]
        let highIndex = lowIndex + 1 // In example: 1 + 1 = 2, [0000][0110][this]

        self.storage[highIndex] = self.storage[highIndex] | lowPart
        self.storage[lowIndex] = self.storage[lowIndex] | highPart
        self.storage[i] = 0
      }
    }

    self.fixInvariants()
  }

  private mutating func prependZerosForShiftLeft(shiftCount: Word) {
    // How many bits/words do we need?
    // Bit arithmetic is done in 'Words' (because that's the type of 'count' arg),
    // but then when calculating 'Word' count we will switch to 'Int'.
    let currentBitCount = Word(self.bitWidth)
    let neededBitCount = currentBitCount + shiftCount
    var neededWordCount = Int(neededBitCount / Word(Word.bitWidth))

    // We need to round UP to the nearest 'Word'
    let hasPartialyFilledWord = neededBitCount % Word(Word.bitWidth) != 0
    if hasPartialyFilledWord {
      neededWordCount += 1
    }

    // Fill additional words with '0'
    let additionalWordCount = neededWordCount - self.storage.count
    self.storage.append(0, repeated: additionalWordCount)
  }

  internal mutating func shiftLeft(count: BigIntHeap) {
    defer { self.checkInvariants() }

    if count.isPositive {
      guard let word = self.guaranteeSingleWord(shiftCount: count) else {
        let msg = "Shifting by more than \(Word.max) is not possible "
                + "(and it is probably not what you wany anyway, "
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
