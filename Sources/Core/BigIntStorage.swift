import Foundation

// swiftlint:disable file_length

/// The binary representation of the `BigInt` on the heap,
/// with the least significant word at index `0`.
///
/// It has no trailing zero elements.
/// If `self.isZero`, then `isNegative == false` and `self.isEmpty == true`.
///
/// - Important:
/// All of the mutating functions have to call
/// `guaranteeUniqueBufferReference` first.
internal struct BigIntStorage: RandomAccessCollection, Equatable, CustomStringConvertible {

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
    get {
      return self.buffer.header.countAndSign < 0
    }
    set {
      // Avoid copy.
      // This check is free because we have to get header from the memory anyway.
      if self.isNegative == newValue {
        return
      }

      self.guaranteeUniqueBufferReference()
      let sign = newValue ? -1 : 1
      self.buffer.header.countAndSign = sign * self.count
    }
  }

  internal private(set) var count: Int {
    get {
      let raw = self.buffer.header.countAndSign
      return raw < 0 ? -raw : raw
    }
    set {
      assert(newValue >= 0)

      // Avoid copy.
      // This check is free because we have to get header from the memory anyway.
      if self.count == newValue {
        return
      }

      self.guaranteeUniqueBufferReference()
      let sign = self.isNegative ? -1 : 1
      self.buffer.header.countAndSign = sign * newValue
    }
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

  // MARK: - Init

  internal init(minimumCapacity: Int) {
    self.buffer = Self.createBuffer(minimumCapacity: minimumCapacity)
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
      self.checkIndex(index: index)
      return self.buffer.withUnsafeMutablePointerToElements { ptr in
        ptr.advanced(by: index).pointee
      }
    }
    set {
      self.checkIndex(index: index)
      self.guaranteeUniqueBufferReference()
      self.buffer.withUnsafeMutablePointerToElements { ptr in
        ptr.advanced(by: index).pointee = newValue
      }
    }
  }

  private func checkIndex(index: Int) {
    // 'Assert' instead of 'precondition', because we control all of the
    // callers (this type is internal).
    // And also because we are cocky.
    assert(0 <= index && index < self.count, "Index out of range")
  }

  // MARK: - Append

  /// Add given `Word` to the buffer.
  internal mutating func append(_ element: Word) {
    self.guaranteeUniqueBufferReference()

    if self.count == self.capacity {
      self.grow()
    }

    self.buffer.withUnsafeMutablePointerToElements { ptr in
      ptr.advanced(by: self.count).pointee = element
    }

    self.count += 1
  }

  /// Assumes that `self.guaranteeUniqueBufferReference` was already called!
  private mutating func grow() {
    let new = Self.createBuffer(
      minimumCapacity: Swift.max(2 * self.capacity, 1),
      header: self.buffer.header
    )

    Self.memcpy(dst: new, src: self.buffer, count: self.count)
    self.buffer = new
  }

  // MARK: - Set

  /// Set `self` to represent given `UInt`.
  internal mutating func set(to value: UInt) {
    self.guaranteeUniqueBufferReference()

    if value.isZero {
      self.count = 0
      self.isNegative = false
    } else {
      self.count = 0
      self.append(value)
      self.isNegative = false
    }
  }

  /// Set `self` to represent given `Int`.
  internal mutating func set(to value: Int) {
    self.guaranteeUniqueBufferReference()

    if value.isZero {
      self.count = 0
      self.isNegative = false
    } else {
      self.count = 0
      self.append(value.magnitude)
      self.isNegative = value.isNegative
    }
  }

  // MARK: - Transform

  /// Apply given function to every word
  internal mutating func transformEveryWord(fn: (Word) -> Word) {
    self.guaranteeUniqueBufferReference()

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

  // MARK: - Equatable

  internal static func == (lhs: Self, rhs: Self) -> Bool {
    let lhsHeader = lhs.buffer.header
    let rhsHeader = rhs.buffer.header

    guard lhsHeader.countAndSign == rhsHeader.countAndSign else {
      return false
    }

    for (l, r) in zip(lhs, rhs) {
      guard l == r else {
        return false
      }
    }

    return true
  }

  // MARK: - Invariants

  internal mutating func fixInvariants() {
    // Trim prefix zeros
    while let last = self.last, last.isZero {
      self.count -= 1
    }

    // Zero is always positive
    if self.isEmpty {
      self.isNegative = false
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

  private mutating func guaranteeUniqueBufferReference() {
    if self.buffer.isUniqueReference() {
      return
    }

    // Well... shit
    let new = Self.createBuffer(
      minimumCapacity: self.capacity, // We are going to mutate it, capacity > count
      header: self.buffer.header
    )

    Self.memcpy(dst: new, src: self.buffer, count: self.count)
  }

  private static func memcpy(dst: Buffer, src: Buffer, count: Int) {
    src.withUnsafeMutablePointerToElements { srcPtr in
      dst.withUnsafeMutablePointerToElements { dstPtr in
        dstPtr.assign(from: srcPtr, count: count)
      }
    }
  }
}
