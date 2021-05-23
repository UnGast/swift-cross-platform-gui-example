import GfxMath

open class MockDrawingBackend: DrawingBackend {
  override open func activate() {
  }

  override open func clip(rect: DRect) {
  }

  override open func resetClip() {
  }

  override open func drawLine(from start: DVec2, to end: DVec2, paint: Paint) {
  }

  override open func drawRect(rect: DRect, paint: Paint) {
  }

  override open func drawCircle(center: DVec2, radius: Double, paint: Paint) {
  }

  override open func drawRoundedRect() {
  }

  override open func drawPath() {
  }

  override open func drawImage(image: Image2, topLeft: DVec2) {
  }

  /**
  // TODO: maybe the result should be a rect to also have access to the position
  */
  override open func measureText(text: String, paint: TextPaint) -> DSize2 {
    .zero
  }

  override open func drawText(text: String, position: DVec2, paint: TextPaint) {
  }

  override open func deactivate() {

  }
}