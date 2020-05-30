import Foundation

/// The binary representation of the value's magnitude,
/// with the least significant word at index `0`.
///
/// It has no trailing zero elements.
/// If `self.isZero`, then `isNegative == false` and `self.isEmpty == true`.
internal struct BigIntStorage:
  RandomAccessCollection, ExpressibleByArrayLiteral,
  CustomStringConvertible {

  // MARK: - Helper types

  private struct Header {

    /// `abs(countAndSign)` is the number of used words.
    /// Sign of the `countAndSign` is the sign of the whole `BigInt`.
    ///
    /// Look at us being clever!
    fileprivate var countAndSign: Int

    fileprivate init(isNegative: Bool, count: Int) {
      // swiftlint:disable:next empty_count
      assert(count >= 0)
      let sign = isNegative ? -1 : 1
      self.countAndSign = sign * count
    }
  }

  internal typealias Word = UInt
  private typealias Buffer = ManagedBufferPointer<Header, Word>

  // MARK: - Properties

  private var buffer: Buffer

  internal var isZero: Bool {
    return self.isEmpty
  }

  internal var isNegative: Bool {
    return self.buffer.header.countAndSign < 0
  }

  internal var count: Int {
    let raw = self.buffer.header.countAndSign
    return raw < 0 ? -raw : raw
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

  // MARK: - Setters

  internal mutating func toggleIsNegative(token: UniqueToken) {
    self.buffer.header.countAndSign = -self.buffer.header.countAndSign
  }

  internal mutating func setIsNegative(_ value: Bool, token: UniqueToken) {
    let sign = value ? -1 : 1
    self.buffer.header.countAndSign = sign * self.count
  }

  private mutating func setCount(_ value: Int, token: UniqueToken) {
    assert(value >= 0)
    let sign = self.isNegative ? -1 : 1
    self.buffer.header.countAndSign = sign * value
  }

  // MARK: - Init

  internal init(minimumCapacity: Int) {
    self.buffer = Self.createBuffer(minimumCapacity: minimumCapacity)
  }

  internal init(arrayLiteral elements: Word...) {
    self.init(minimumCapacity: elements.count)

    // Well, we have just created this buffer... it is trivially unique
    let token = UniqueToken()
    for element in elements {
      self.append(element, token: token)
    }
  }

  // MARK: - Create buffer

  /// `ManagedBufferPointer` will call our `deinit`.
  /// This is bascally kind of memory overlay thingie.
  private class LetItGo {

    private var buffer: Buffer {
      return Buffer(unsafeBufferObject: self)
    }

    deinit {
      // TODO: Test deinit
      // Let it go, let it go
      // Can't hold it back anymore
      // Let it go, let it go
      // Turn away and slam the door
      //
      // I don't care
      // What they're going to say
      // Let the storm rage on
      // The cold never bothered me anyway
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
      assert(0 <= index && index < self.count, "Index out of range")
      return self.buffer.withUnsafeMutablePointerToElements { ptr in
        ptr.advanced(by: index).pointee
      }
    }
    set {
      let token = self.guaranteeUniqueBufferReference()
      self.setIndex(index: index, value: newValue, token: token)
    }
  }

  internal mutating func setIndex(index: Int, value: Word, token: UniqueToken) {
    assert(0 <= index && index < self.count, "Index out of range")
    self.buffer.withUnsafeMutablePointerToElements { ptr in
      ptr.advanced(by: index).pointee = value
    }
  }

  // MARK: - Append

  internal mutating func append(_ element: Word, token: UniqueToken) {
    if self.count == self.capacity {
      self.grow(token: token)
    }

    self.buffer.withUnsafeMutablePointerToElements { ptr in
      ptr.advanced(by: self.count).pointee = element
    }

    self.setCount(self.count + 1, token: token)
  }

  private mutating func grow(token: UniqueToken) {
    let new = Self.createBuffer(
      minimumCapacity: Swift.max(2 * self.capacity, 1),
      header: self.buffer.header
    )

    Self.memcpy(dst: new, src: self.buffer, count: self.count)
    self.buffer = new
  }

  // MARK: - Map

  internal mutating func map(fn: (Word) -> Word, token: UniqueToken) {
    self.buffer.withUnsafeMutablePointerToElements { startPtr in
      let endPtr = startPtr.advanced(by: self.count)

      var ptr = startPtr
      while ptr != endPtr {
        let old = ptr.pointee
        ptr.pointee = fn(old)
        ptr = ptr.successor()
      }
    }
  }

  // MARK: - Add

  internal mutating func addMagnitude(other: Smi.Storage, token: UniqueToken) {
    fatalError()
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

  // MARK: - Invariants

  internal mutating func fixInvariants(token: UniqueToken) {
    // Trim prefix zeros
    while let last = self.last, last.isZero {
      self.setCount(self.count - 1, token: token)
    }

    // Zero is always positive
    if self.isEmpty {
      self.setIsNegative(false, token: token)
    }
  }

  internal func checkInvariants(source: StaticString = #function) {
    if let last = self.last {
      assert(last != 0, "\(source): zero prefix in BigInt")
    } else {
      // 'self.data' is empty
      assert(!self.isNegative, "\(source): isNegative with empty data")
    }
  }

  // MARK: - Helpers

  /// Things can get complicated and defensively calling
  /// `guaranteeUniqueBufferReference` is `meh`.
  internal struct UniqueToken { }

  internal mutating func guaranteeUniqueBufferReference() -> UniqueToken {
    if self.buffer.isUniqueReference() {
      return UniqueToken()
    }

    // Well... shit
    let new = Self.createBuffer(
      minimumCapacity: self.capacity, // We are going to mutate it, capacity > count
      header: self.buffer.header
    )

    Self.memcpy(dst: new, src: self.buffer, count: self.count)
    // At this point 'self.buffer' is not uniquely referenced because
    // well... we still reference it in 'new'.
    return UniqueToken()
  }

  private static func memcpy(dst: Buffer, src: Buffer, count: Int) {
    src.withUnsafeMutablePointerToElements { srcPtr in
      dst.withUnsafeMutablePointerToElements { dstPtr in
        dstPtr.assign(from: srcPtr, count: count)
      }
    }
  }
}
