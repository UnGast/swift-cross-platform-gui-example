import VisualAppBase
import Drawing
import SkiaKit

open class LeafWidget: Widget {
  open func draw(_ drawingContext: DrawingContext) {
    fatalError("draw() not implemented for widget: \(self)")
  }

  open func draw(_ drawingContext: DrawingContext, canvas: Canvas) {
    draw(drawingContext)
  }
}