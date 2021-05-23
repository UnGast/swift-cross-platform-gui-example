import SkiaKit
import GfxMath

extension Paint {
  public convenience init(color: GfxMath.Color, style: Paint.Style, isAntialias: Bool = true) {
    self.init()
    self.color = Color(color)
    self.style = style
    self.isAntialias = isAntialias
  }

  public convenience init(fill color: GfxMath.Color) {
    self.init()
    self.style = .fill
    self.color = Color(color)
  }

  public convenience init(stroke color: GfxMath.Color, width: Double) {
    self.init()
    self.style = .stroke
    self.color = Color(color)
    self.strokeWidth = Float(width)
  }
}