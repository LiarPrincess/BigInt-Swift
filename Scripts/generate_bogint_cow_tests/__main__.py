def print_tests(name, operator):
  name_upper = name
  name_lower = name_upper.lower()

  print(f'''\
  // MARK: - {name_upper}

  /// This test actually DOES make sense, because, even though 'BigInt' is immutable,
  /// the heap that is points to is not.
  func test_{name_lower}_toCopy_doesNotModifyOriginal() {{
    // smi {operator} smi
    var value = BigInt(SmiStorage.max)
    var copy = value
    _ = copy {operator} self.smiValue
    XCTAssertEqual(value, BigInt(SmiStorage.max))

    // smi {operator} heap
    value = BigInt(SmiStorage.max)
    copy = value
    _ = copy {operator} self.heapValue
    XCTAssertEqual(value, BigInt(SmiStorage.max))

    // heap {operator} smi
    value = BigInt(HeapWord.max)
    copy = value
    _ = copy {operator} self.smiValue
    XCTAssertEqual(value, BigInt(HeapWord.max))

    // heap {operator} heap
    value = BigInt(HeapWord.max)
    copy = value
    _ = copy {operator} self.heapValue
    XCTAssertEqual(value, BigInt(HeapWord.max))
  }}

  /// This test actually DOES make sense, because, even though 'BigInt' is immutable,
  /// the heap that is points to is not.
  func test_{name_lower}_toInout_doesNotModifyOriginal() {{
    // smi {operator} smi
    var value = BigInt(SmiStorage.max)
    self.{name_lower}Smi(toInout: &value)
    XCTAssertEqual(value, BigInt(SmiStorage.max))

    // smi {operator} heap
    value = BigInt(SmiStorage.max)
    self.{name_lower}Heap(toInout: &value)
    XCTAssertEqual(value, BigInt(SmiStorage.max))

    // heap {operator} smi
    value = BigInt(HeapWord.max)
    self.{name_lower}Smi(toInout: &value)
    XCTAssertEqual(value, BigInt(HeapWord.max))

    // heap {operator} heap
    value = BigInt(HeapWord.max)
    self.{name_lower}Heap(toInout: &value)
    XCTAssertEqual(value, BigInt(HeapWord.max))
  }}

  private func {name_lower}Smi(toInout value: inout BigInt) {{
    _ = value {operator} self.smiValue
  }}

  private func {name_lower}Heap(toInout value: inout BigInt) {{
    _ = value {operator} self.heapValue
  }}

  func test_{name_lower}Equal_toCopy_doesNotModifyOriginal() {{
    // smi {operator} smi
    var value = BigInt(SmiStorage.max)
    var copy = value
    copy {operator}= self.smiValue
    XCTAssertEqual(value, BigInt(SmiStorage.max))

    // smi {operator} heap
    value = BigInt(SmiStorage.max)
    copy = value
    copy {operator}= self.heapValue
    XCTAssertEqual(value, BigInt(SmiStorage.max))

    // heap {operator} smi
    value = BigInt(HeapWord.max)
    copy = value
    copy {operator}= self.smiValue
    XCTAssertEqual(value, BigInt(HeapWord.max))

    // heap {operator} heap
    value = BigInt(HeapWord.max)
    copy = value
    copy {operator}= self.heapValue
    XCTAssertEqual(value, BigInt(HeapWord.max))
  }}

  func test_{name_lower}Equal_toInout_doesModifyOriginal() {{
    // smi {operator} smi
    var value = BigInt(SmiStorage.max)
    self.{name_lower}EqualSmi(toInout: &value)
    XCTAssertNotEqual(value, BigInt(SmiStorage.max))

    // smi {operator} heap
    value = BigInt(SmiStorage.max)
    self.{name_lower}EqualHeap(toInout: &value)
    XCTAssertNotEqual(value, BigInt(SmiStorage.max))

    // heap {operator} smi
    value = BigInt(HeapWord.max)
    self.{name_lower}EqualSmi(toInout: &value)
    XCTAssertNotEqual(value, BigInt(HeapWord.max))

    // heap {operator} heap
    value = BigInt(HeapWord.max)
    self.{name_lower}EqualHeap(toInout: &value)
    XCTAssertNotEqual(value, BigInt(HeapWord.max))
  }}

  private func {name_lower}EqualSmi(toInout value: inout BigInt) {{
    value {operator}= self.smiValue
  }}

  private func {name_lower}EqualHeap(toInout value: inout BigInt) {{
    value {operator}= self.heapValue
  }}
''')

if __name__ == '__main__':
  print_tests('Add', '+')
  print_tests('Sub', '-')
  print_tests('Mul', '*')
  print_tests('Div', '/')
  print_tests('Mod', '%')
