import VisualAppBase
import GfxMath
import SkiaKit
import Drawing

public class DrawingManager {
  var rootWidget: Widget

  public init(rootWidget: Widget) {
    self.rootWidget = rootWidget
  }

  public func processQueue(_ queue: Widget.LifecycleMethodInvocationQueue, drawingContext: DrawingContext, canvas: SkiaKit.Canvas) {
    /*var iterationStates = [(Parent?, DrawingContext, CanvasState, Array<Widget>.Iterator)]()
    iterationStates.append((nil, drawingContext, CanvasState(), [rootWidget].makeIterator()))*/

    var drawStack = [DrawingStackItem]()
    drawStack.append(DrawingStackItem(
      parent: nil,
      parentCanvasState: CanvasState(),
      childrenIterator: [rootWidget].makeIterator()))

    outer: while var stackItem = drawStack.last {
      while let widget = stackItem.childrenIterator.next() {
        //(parent, parentDrawingContext, iterator)
        //iterationStates[iterationStates.count - 1].2 = iterator

        if widget.visibility == .visible && widget.opacity > 0 {
          var canvasState = stackItem.parentCanvasState

         // let childDrawingContext: DrawingContext = parentDrawingContext.clone()
          
          //childDrawingContext.opacity = widget.opacity
          //childDrawingContext.transform(.translate(widget.layoutedPosition))
          //childDrawingContext.transform(widget.transform)
          canvasState.transforms.append(.translate(widget.layoutedPosition))
          // TODO: maybe the scrolling translation should be added to the parent widget context before adding the iterator to the list?
          if !widget.unaffectedByParentScroll, let parent = widget.parent as? Widget, parent.overflowX == .scroll || parent.overflowY == .scroll {
            //childDrawingContext.transform(.translate(-parent.currentScrollOffset))
          }
          if widget.overflowX == .cut || widget.overflowX == .scroll || widget.overflowY == .cut || widget.overflowY == .scroll {
            /*let translationTestRect = drawingContext.preprocess(DRect(min: .zero, size: widget.layoutedSize))
            var clipRect = translationTestRect

            if widget.overflowX == .cut || widget.overflowX == .scroll {
              clipRect.min.x = 0
              clipRect.size.x = widget.layoutedSize.width
            }
            if widget.overflowY == .cut || widget.overflowY == .scroll {
              clipRect.min.y = 0
              clipRect.size.y = widget.layoutedSize.height
            }

            childDrawingContext.clip(rect: clipRect)*/
          }
          //childDrawingContext.lock()

          //childDrawingContext.beginDrawing()

          apply(canvasState: canvasState, to: canvas)

          if widget.background != .transparent {
            //childDrawingContext.drawRect(rect: DRect(min: .zero, size: widget.layoutedSize), paint: Paint(color: widget.background))

            let paint = Paint(color: widget.background, style: .fill, isAntialias: true)
            canvas.drawRect(DRect(min: .zero, size: widget.layoutedSize), paint: paint)
            canvas.flush()
          }

          // TODO: probably the border should be drawn after all children have been drawn, to avoid the border being overlpassed
          if widget.borderColor != .transparent && widget.borderWidth != .zero {
            drawBorders(widget: widget, canvas: canvas)
            canvas.flush()
          }

          if widget.padding.left != 0 || widget.padding.top != 0 {
            //childDrawingContext.transform(.translate(DVec2(widget.padding.left, widget.padding.top)))
            canvasState.transforms.append(.translate(DVec2(widget.padding.left, widget.padding.top)))
            apply(canvasState: canvasState, to: canvas)
          }

          //childDrawingContext.lock()

          if let leafWidget = widget as? LeafWidget {
            leafWidget.draw(drawingContext, canvas: canvas)
          }
          canvas.flush()

          //childDrawingContext.endDrawing()

          if !(widget is LeafWidget) {
            //iterationStates.append((widget, childDrawingContext, widget.children.makeIterator()))
            drawStack.append(DrawingStackItem(parent: widget, parentCanvasState: canvasState, childrenIterator: widget.children.makeIterator()))
            continue outer
          }
        }
      }

      if let parent = stackItem.parent, parent.debugLayout {
        //drawingContext.drawRect(rect: parent.globalBounds, paint: Paint(strokeWidth: 2.0, strokeColor: .red))
      }

      /*if let parent = parent as? Widget, parent.scrollingEnabled.x || parent.scrollingEnabled.y {
        parentDrawingContext.beginDrawing()
        parent.drawScrollbars(parentDrawingContext)
        parentDrawingContext.endDrawing()
      }*/

      //iterationStates.removeLast()
      drawStack.removeLast()
    }

    /*canvas.clear(color: Colors.yellow)
    canvas.translate(dx: 100, dy: 100)
    canvas.drawRect(DRect(min: DVec2(20,20), max: DVec2(1000, 1000)), Paint(color: .black, style: .fill, isAntialias: true))*/
  }

  private func drawBorders(widget: Widget, canvas: Canvas) {
    if widget.borderWidth.top > 0 {
      canvas.drawLine(
        DVec2(0, widget.borderWidth.top / 2),
        DVec2(widget.layoutedSize.width, widget.borderWidth.top / 2),
        paint: Paint(stroke: widget.borderColor, width: widget.borderWidth.top))
    }

    if widget.borderWidth.right > 0 {
      canvas.drawLine(
        DVec2(widget.layoutedSize.width - widget.borderWidth.right / 2, 0),
        DVec2(widget.layoutedSize.width - widget.borderWidth.right / 2, widget.layoutedSize.height),
        paint: Paint(stroke: widget.borderColor, width: widget.borderWidth.right))
    }

    if widget.borderWidth.bottom > 0 {
      canvas.drawLine(
        DVec2(0, widget.layoutedSize.height - widget.borderWidth.bottom / 2),
        DVec2(widget.layoutedSize.width, widget.layoutedSize.height - widget.borderWidth.bottom / 2),
        paint: Paint(stroke: widget.borderColor, width: widget.borderWidth.bottom))
    }

    if widget.borderWidth.left > 0 {
      canvas.drawLine(
        DVec2(widget.borderWidth.left / 2, 0),
        DVec2(widget.borderWidth.left / 2, widget.layoutedSize.height),
        paint: Paint(stroke: widget.borderColor, width: widget.borderWidth.left))
    }
  }

  private func apply(canvasState: CanvasState, to canvas: Canvas) {
    canvas.resetMatrix()
    for transform in canvasState.transforms.reversed() {
      switch transform {
        case let .translate(translation):
          canvas.translate(dx: Float(translation.x), dy: Float(translation.y))
        default:
          break
      }
    }
  }

  private struct CanvasState {
    var transforms: [DTransform2] = []
    var clipRect: DRect?
  }

  private class DrawingStackItem {
    var parent: Widget?
    var parentCanvasState: CanvasState
    var childrenIterator: Array<Widget>.Iterator

    init(parent: Widget?, parentCanvasState: CanvasState, childrenIterator: Array<Widget>.Iterator) {
      self.parent = parent
      self.parentCanvasState = parentCanvasState
      self.childrenIterator = childrenIterator
    }
  }
}