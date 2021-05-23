import SkiaKit
import GfxMath

extension SkiaKit.Color {
  public init(_ color: GfxMath.Color) {
    self.init(r: color.r, g: color.g, b: color.b, a: color.a)
  }
}