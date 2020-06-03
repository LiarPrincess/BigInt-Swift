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

      // We will allow seting 'isNegative' when the value is '0',
      // just assume that user know what they are doing.

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

  internal init(repeating repeatedValue: Word, count: Int) {
    self.init(minimumCapacity: count)
    Self.memset(dst: self.buffer, value: repeatedValue, count: count)
  }

  internal init(value: UInt) {
    self.init(minimumCapacity: 1)
    self.set(to: value)
  }

  internal init(value: Int) {
    self.init(minimumCapacity: 1)
    self.set(to: value)
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
    self.guaranteeUniqueBufferReference(withMinimumCapacity: self.count + 1)

    self.buffer.withUnsafeMutablePointerToElements { ptr in
      ptr.advanced(by: self.count).pointee = element
    }

    self.count += 1
  }

  /// Add all of the `Word`s from given collection to the buffer.
  internal mutating func append<C: Collection>(
    contentsOf other: C
  ) where C.Element == Word {
    if other.isEmpty {
      return
    }

    let newCount = self.count + other.count
    self.guaranteeUniqueBufferReference(withMinimumCapacity: newCount)

    self.buffer.withUnsafeMutablePointerToElements { startPtr in
      var ptr = startPtr.advanced(by: self.count)
      for word in other {
        ptr.pointee = word
        ptr = ptr.successor()
      }
    }

    self.count = newCount
  }

  // MARK: - Prepend

  /// Add given `Word`  at the start of the buffer specified number of times.
  internal mutating func prepend(_ element: Word, repeated count: Int) {
    // swiftlint:disable:next empty_count
    assert(count >= 0)

    if count.isZero {
      return
    }

    let newCount = self.count + count
    if self.buffer.isUniqueReference() && self.capacity >= newCount {
      // Our current buffer is big enough to do the whole operation,
      // no new allocation is needed.

      self.buffer.withUnsafeMutablePointerToElements { startPtr in
        // Move current words back
        let targetPtr = startPtr.advanced(by: count)
        targetPtr.assign(from: startPtr, count: self.count)

        // Reset old words
        startPtr.assign(repeating: element, count: count)
      }

      self.count = newCount
      return
    }

    let new = Self.createBuffer(
      minimumCapacity: newCount,
      header: Header(isNegative: self.isNegative, count: newCount)
    )

    self.buffer.withUnsafeMutablePointerToElements { selfStartPtr in
      new.withUnsafeMutablePointerToElements { newStartPtr in
        // Populate new (shifted) words
        let targetPtr = newStartPtr.advanced(by: count)
        targetPtr.assign(from: selfStartPtr, count: self.count)

        // Set the prefix to the requested word.
        // We don't have to do this if 'element' is '0', because the buffer
        // is already zeroed.
        if !element.isZero {
          newStartPtr.assign(repeating: element, count: count)
        }
      }
    }

    self.buffer = new
  }

  // MARK: - Set

  /// Set `self` to represent given `UInt`.
  internal mutating func set(to value: UInt) {
    // We do not have to call 'self.guaranteeUniqueBufferReference'
    // because all of the functions we are using will do this anyway.

    if value.isZero {
      self.setToZero()
    } else {
      self.count = 0
      self.append(value)
      self.isNegative = false
    }
  }

  /// Set `self` to represent given `Int`.
  internal mutating func set(to value: Int) {
    // We do not have to call 'self.guaranteeUniqueBufferReference'
    // because all of the functions we are using will do this anyway.

    if value.isZero {
      self.setToZero()
    } else {
      self.count = 0
      self.append(value.magnitude)
      self.isNegative = value.isNegative
    }
  }

  internal mutating func setToZero() {
    // We do not have to call 'self.guaranteeUniqueBufferReference'
    // because all of the functions we are using will do this anyway.
    self.count = 0
    self.isNegative = false
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

  // MARK: - Reserve capacity

  internal mutating func reserveCapacity(_ capacity: Int) {
    self.guaranteeUniqueBufferReference(withMinimumCapacity: capacity)
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

  // MARK: - Unique

  private mutating func guaranteeUniqueBufferReference() {
    if self.buffer.isUniqueReference() {
      return
    }

    // Well... shit
    let new = Self.createBuffer(
      minimumCapacity: self.capacity,
      header: self.buffer.header
    )

    Self.memcpy(dst: new, src: self.buffer, count: self.count)
    self.buffer = new
  }

  private mutating func guaranteeUniqueBufferReference(
    withMinimumCapacity minimumCapacity: Int
  ) {
    if self.buffer.isUniqueReference() && self.capacity >= minimumCapacity {
      return
    }

    // Well... shit, we have to allocate new buffer,
    // but we can grow at the same time (2 birds - 1 stone).
    let growFactor = 2
    let capacity = Swift.max(minimumCapacity, growFactor * self.capacity, 1)

    let new = Self.createBuffer(
      minimumCapacity: capacity,
      header: self.buffer.header
    )

    Self.memcpy(dst: new, src: self.buffer, count: self.count)
    self.buffer = new
  }

  private static func memcpy(dst: Buffer, src: Buffer, count: Int) {
    src.withUnsafeMutablePointerToElements { srcPtr in
      dst.withUnsafeMutablePointerToElements { dstPtr in
        dstPtr.assign(from: srcPtr, count: count)
      }
    }
  }

  private static func memset(dst: Buffer, value: Word, count: Int) {
    dst.withUnsafeMutablePointerToElements { dstPtr in
      dstPtr.assign(repeating: value, count: count)
    }
  }
}
