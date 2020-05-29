import Foundation

private func memcpy(dst: UnsafeMutablePointer<BigIntStorage.Word>,
                    src: UnsafeMutablePointer<BigIntStorage.Word>,
                    count: Int) {
  let dstRaw = UnsafeMutableRawPointer(dst)
  let srcRaw = UnsafeRawPointer(src)
  let byteCount = count * MemoryLayout<BigIntStorage.Word>.stride
  Foundation.memcpy(dstRaw, srcRaw, byteCount)
}

// MARK: - BigIntStorage

internal struct BigIntStorage:
  RandomAccessCollection, ExpressibleByArrayLiteral,
  CustomStringConvertible {

  // MARK: - Helper types

  private struct Header {

    // Look at us being clever!
    private var countAndSign: Int

    fileprivate init(isNegative: Bool, count: Int) {
      // swiftlint:disable:next empty_count
      assert(count >= 0)
      let sign = isNegative ? -1 : 1
      self.countAndSign = sign * count
    }

    fileprivate var count: Int {
      get { return Swift.abs(self.countAndSign) }
      set {
        assert(newValue >= 0)
        let sign = self.isNegative ? -1 : 1
        self.countAndSign = sign * newValue
      }
    }

    fileprivate var isNegative: Bool {
      get { return self.countAndSign < 0 }
      set {
        let sign = newValue ? -1 : 1
        self.countAndSign = sign * self.count
      }
    }
  }

  internal typealias Word = UInt
  private typealias Buffer = ManagedBufferPointer<Header, Word>

  // MARK: - Properties

  private var buffer: Buffer

  internal var isNegative: Bool {
    get { return self.buffer.header.isNegative }
    set { self.buffer.header.isNegative = newValue }
  }

  internal private(set) var count: Int {
    get { return self.buffer.header.count }
    set { self.buffer.header.count = newValue }
  }

  internal var capacity: Int {
    return self.buffer.capacity
  }

  internal var startIndex: Int {
    return 0
  }

  internal var endIndex: Int {
    return self.count
  }

  internal mutating func isUniquelyReferenced() -> Bool {
    return self.buffer.isUniqueReference()
  }

  // MARK: - Init

  internal init(minimumCapacity: Int) {
    self.buffer = Self.createBuffer(minimumCapacity: minimumCapacity)
  }

  internal init(arrayLiteral elements: Word...) {
    self.init(minimumCapacity: elements.count)

    for element in elements {
      self.append(element)
    }
  }

  // MARK: - Create buffer

  /// `ManagedBufferPointer` will call our `deinit`.
  /// It is bascally kind of memory overlay thingie.
  ///
  /// ```
  /// Let it go, let it go
  /// Can't hold it back anymore
  /// Let it go, let it go
  /// Turn away and slam the door
  ///
  /// I don't care
  /// What they're going to say
  /// Let the storm rage on
  /// The cold never bothered me anyway
  /// ```
  private class LetItGo {

    private var buffer: Buffer {
      return Buffer(unsafeBufferObject: self)
    }

    deinit {
      // TODO: Test deinit
    }
  }

  private static func createBuffer(minimumCapacity: Int) -> Buffer {
    return Self.createBuffer(
      minimumCapacity: minimumCapacity,
      header: Header(isNegative: false, count: 0)
    )
  }

  private static func createBuffer(minimumCapacity: Int, header: Header) -> Buffer {
    // swiftlint:disable:next trailing_closure
    return Buffer(
      bufferClass: LetItGo.self,
      minimumCapacity: minimumCapacity,
      makingHeaderWith: { _, _  in header }
    )
  }

  // MARK: - Subscript

  internal subscript(index: Int) -> Word {
    get {
      self.checkValidSubscript(index)
      return self.buffer.withUnsafeMutablePointerToElements { ptr in
        ptr.advanced(by: index).pointee
      }
    }
    nonmutating set {
      self.checkValidSubscript(index)
      self.buffer.withUnsafeMutablePointerToElements { ptr in
        ptr.advanced(by: index).pointee = newValue
      }
    }
  }

  /// Traps unless the given `index` is valid for subscripting,
  /// i.e. `0 <= index < count`.
  private func checkValidSubscript(_ index : Int) {
    precondition(0 <= index && index < self.count, "Index out of range")
  }

  // MARK: - Append

  internal mutating func append(_ element: Word) {
    if self.count == self.capacity {
      self.grow()
    }

    self.buffer.withUnsafeMutablePointerToElements { ptr in
      ptr.advanced(by: self.count).pointee = element
    }

    self.count += 1
  }

  private mutating func grow() {
    let new = Self.createBuffer(
      minimumCapacity: Swift.max(2 * self.capacity, 1),
      header: self.buffer.header
    )

    self.buffer.withUnsafeMutablePointerToElements { srcPtr in
      new.withUnsafeMutablePointerToElements { dstPtr in
        memcpy(dst: dstPtr, src: srcPtr, count: self.count)
      }
    }

    self.buffer = new
  }

  // MARK: - String

  internal var description: String {
    var result = "BigIntStorage("
    result.append("isNegative: \(self.isNegative), ")
    result.append("capacity: \(self.capacity), ")

    if self.count < 10 {
      result.append("words: [")
      for (index, word) in self.enumerated() {
        result.append("0x")
        result.append(String(word, radix: 2, uppercase: false))

        let isLast = index == self.count - 1
        if !isLast {
          result.append(", ")
        }
      }
      result.append("]")
    } else {
      result.append("count: \(self.count)")
    }

    result.append(")")
    return result
  }
}
