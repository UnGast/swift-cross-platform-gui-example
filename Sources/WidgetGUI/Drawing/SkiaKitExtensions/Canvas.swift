import SkiaKit
import GfxMath

extension Canvas {
  public func drawPoint(_ point: DVec2, paint: Paint) {
    drawPoint(Float(point.x), Float(point.y), paint)
  }

  public func drawPoint(_ point: DVec2, color: GfxMath.Color) {
    drawPoint(point, paint: Paint(fill: color))
  }

  public func drawLine(_ start: DVec2, _ end: DVec2, paint: Paint) {
    drawLine(x0: Float(start.x), y0: Float(start.y), x1: Float(end.x), y1: Float(end.y), paint: paint)
  }

  public func drawRect(_ rect: DRect, paint: Paint) {
    drawRect(SkiaKit.Rect(x: Float(rect.min.x), y: Float(rect.min.y), width: Float(rect.size.width), height: Float(rect.size.height)), paint)
  }

  public func drawCircle(center: DVec2, radius: Double, paint: Paint) {
    drawCircle(Float(center.x), Float(center.y), Float(radius), paint)
  }
}