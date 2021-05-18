import Swim

final public class Image2: Hashable {
  public private(set) var data: Swim.Image<RGBA, UInt8>
  public var invalid: Bool = true 

  public init(fromRGBA data: Swim.Image<RGBA, UInt8>) {
    self.data = data
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }

  public func updateData(_ newData: Swim.Image<RGBA, UInt8>) throws {
    if newData.width != data.width || newData.height != data.height {
      throw DataUpdateSizeMismatchError()
    }

    data = newData
    invalid = true
  }

  public static func == (lhs: Image2, rhs: Image2) -> Bool {
    lhs === rhs
  }

  public struct DataUpdateSizeMismatchError: Error {
    let description = "updated data size must match old data size"
  }
}