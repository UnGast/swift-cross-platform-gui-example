import GfxMath

open class DrawingBackend {
  public init() {}

  open func activate() {

  }

  open func clip(rect: DRect) {
    fatalError("clip() not implemented")
  }

  open func resetClip() {
    fatalError("resetClip() not implemented")
  }

  open func drawLine(from start: DVec2, to end: DVec2, paint: Paint) {
    fatalError("drawLine() not implemented")
  }

  open func drawRect(rect: DRect, paint: Paint) {
    fatalError("drawRect() not implemented")
  }

  open func drawCircle(center: DVec2, radius: Double, paint: Paint) {
    fatalError("drawCircle() not implemented")
  }

  open func drawRoundedRect() {

  }

  open func drawPath() {
    
  }

  open func drawImage(image: Image2, topLeft: DVec2) {
    fatalError("drawImage() not implemented")
  }

  /**
  // TODO: maybe the result should be a rect to also have access to the position
  */
  open func measureText(text: String, paint: TextPaint) -> DSize2 {
    fatalError("measureText() not implemented")
  }

  open func drawText(text: String, position: DVec2, paint: TextPaint) {
    fatalError("drawText() not implemented")
  }

  open func deactivate() {

  }
}