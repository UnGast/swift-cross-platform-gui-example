import CustomGraphicsMath
import Foundation

public class RenderObjectTreeSliceRenderer {
  private var renderObjectMeta: [ObjectIdentifier: Any] = [:]
  private var destroyed = false
  private var context: ApplicationContext

  deinit {
    if !destroyed {
      fatalError("deinitialized before destroy() was called")
    }
  }

  public init(context: ApplicationContext) {
    self.context = context
  }

  public func render(_ slice: RenderObjectTree.TreeSlice, with backendRenderer: Renderer) {
    var currentPath = slice.startPath
    var renderedNodeCount = 0

    outer: while let currentNode = slice[currentPath] {
      renderedNodeCount += 1

      if currentNode.isBranching, currentNode.children.count > 0 {
        renderOpen(node: currentNode, with: backendRenderer)
        currentPath = currentPath/0
      } else {
        if currentNode.isBranching {
          renderClose(node: currentNode, with: backendRenderer)
        } else {
          renderLeaf(node: currentNode, with: backendRenderer)
        }

        var currentParent: RenderObject? = currentNode.parent
        var currentChildPath = currentPath

        while currentParent != nil {
          if currentParent!.children.count > currentChildPath.last! + 1 {
            currentPath = currentChildPath + 1
            continue outer
          } else {
            renderClose(node: currentParent!, with: backendRenderer)
          }

          currentChildPath = currentChildPath.dropLast()
          currentParent = currentParent?.parent
        }

        break
      }
    }
  }

  private func renderOpen(node: RenderObject, with backendRenderer: Renderer) {
    let timestamp = context.system.currentTime

    switch node {

    case let node as RenderStyleRenderObject:
      if let fillRenderValue = node.fill {
        let fill = fillRenderValue.getValue(at: timestamp)
        if fillRenderValue.isTimed {
          switch fill {
          case let .Color(value):
            backendRenderer.fillColor(value)

          case let .Image(value, position):
            backendRenderer.fillImage(value, position: position)
          }
        } else {
          switch fill {
          case let .Color(value):
            backendRenderer.fillColor(value)

          case let .Image(value, position):
            let id = ObjectIdentifier(node)
            if let cachedLoadedFill = renderObjectMeta[id] as? LoadedFill {
              backendRenderer.applyFill(cachedLoadedFill)
            } else {
              let loadedFill = backendRenderer.fillImage(value, position: position)
              renderObjectMeta[id] = loadedFill
            }
          }
        }
        // performFill = true
      } else {
        backendRenderer.fillColor(.Transparent)
      }

      if let strokeWidth = node.strokeWidth,
        let strokeColor = node.strokeColor
      {
        backendRenderer.strokeWidth(strokeWidth)
        backendRenderer.strokeColor(strokeColor.getValue(at: timestamp))
        // performStroke = true
      } else {
        backendRenderer.strokeWidth(0)
        backendRenderer.strokeColor(.Transparent)
      }

    case let node as RenderObject.Translation:
      backendRenderer.translate(node.translation)
    case let node as RenderObject.Clip:
      // TODO: right now, clip areas can't be nested --> implement clip area bounds stack
      backendRenderer.clipArea(bounds: node.clipBounds)
    default:
      break
    }
  }

  private func renderClose(node: RenderObject, with backendRenderer: Renderer) {
    switch node {
    case let node as RenderStyleRenderObject:
      backendRenderer.fillColor(.Transparent)
      backendRenderer.strokeWidth(0)
      backendRenderer.strokeColor(.Transparent)
    case let node as TranslationRenderObject:
      backendRenderer.translate(-node.translation)
    case let node as ClipRenderObject:
      backendRenderer.releaseClipArea()
    default:
      break
    }
  }

  private func renderLeaf(node: RenderObject, with backendRenderer: Renderer) {
    switch node {
    case let node as RectangleRenderObject:
      backendRenderer.beginPath()
      if let cornerRadii = node.cornerRadii {
        backendRenderer.roundedRectangle(node.rect, cornerRadii: cornerRadii)
      } else {
        backendRenderer.rectangle(node.rect)
      }
      backendRenderer.fill()
      backendRenderer.stroke()

    case let node as CustomRenderObject:
      // TODO: this might be a dirty solution
      backendRenderer.endFrame()
      node.render(backendRenderer)
      backendRenderer.beginFrame()

    case let node as EllipsisRenderObject:
      backendRenderer.beginPath()
      backendRenderer.ellipse(node.bounds)
      backendRenderer.fill()
      backendRenderer.stroke()

    case let node as LineSegmentRenderObject:
      backendRenderer.beginPath()
      backendRenderer.lineSegment(from: node.start, to: node.end)
      backendRenderer.stroke()

    case let node as PathRenderObject:
      backendRenderer.beginPath()
      backendRenderer.path(node.path)
      backendRenderer.fill()
      backendRenderer.stroke()

    case let node as RenderObject.Text:
      backendRenderer.text(
        node.text, fontConfig: node.fontConfig, color: node.color, topLeft: node.topLeft,
        maxWidth: node.maxWidth)

    default:
      break
    }
  }

  public func destroy() {

  }
}