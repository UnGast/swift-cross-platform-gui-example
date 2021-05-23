import VisualAppBase
import GfxMath
import SkiaKit
import Drawing

public class Drawing: LeafWidget {
  private let _draw: (Canvas) -> ()

  public init(draw: @escaping (Canvas) -> ()) {
      self._draw = draw
  }

  override public func performLayout(constraints: BoxConstraints) -> DSize2 {
    constraints.constrain(DSize2(40, 40)) // arbitrary size to see something when min size constraints is 0
  }

  override public func draw(_ drawingContext: DrawingContext, canvas: Canvas) {
    _draw(canvas)
  }
}