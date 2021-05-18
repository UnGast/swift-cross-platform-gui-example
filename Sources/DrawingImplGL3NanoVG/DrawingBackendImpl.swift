import GfxMath
import CnanovgGL3
import Drawing
import HID

open class GL3NanoVGDrawingBackend: DrawingBackend {
  private let surface: OpenGLWindowSurface
  private let nvg: UnsafeMutablePointer<NVGcontext>

  private var fontIds = [String: Int32]()
  private var imageIds = [Image2: Int32]()

  public init(surface: OpenGLWindowSurface) {
    self.surface = surface
    self.nvg = nvgCreateGL3(
      Int32(NVG_ANTIALIAS.rawValue | NVG_STENCIL_STROKES.rawValue | NVG_DEBUG.rawValue))
  }

  override public func activate() {
    let drawableSize = surface.getDrawableSize()
    nvgBeginFrame(nvg, Float(drawableSize.width), Float(drawableSize.height), 1.0)
  }

  override open func clip(rect: DRect) {
    nvgScissor(nvg, Float(rect.min.x), Float(rect.min.y), Float(rect.size.width), Float(rect.size.height))
  }

  override open func resetClip() {
    nvgResetScissor(nvg)
  }

  func with(paint: Paint, block: () -> ()) {
    var performFill = false
    var performStroke = false
    if let color = paint.color {
      nvgFillColor(nvg, color.toNVG())
      performFill = true
    }
    if let strokeWidth = paint.strokeWidth, let strokeColor = paint.strokeColor {
      nvgStrokeWidth(nvg, Float(strokeWidth))
      nvgStrokeColor(nvg, strokeColor.toNVG())
      performStroke = true
    }

    block()

    if performFill {
      nvgFill(nvg)
    }
    if performStroke {
      nvgStroke(nvg)
    }
  }

  override open func drawLine(from start: DVec2, to end: DVec2, paint: Paint) {
    var performFill = false
    var performStroke = false
    if let color = paint.color {
      nvgFillColor(nvg, color.toNVG())
      performFill = true
    }
    if let strokeWidth = paint.strokeWidth, let strokeColor = paint.strokeColor {
      nvgStrokeWidth(nvg, Float(strokeWidth))
      nvgStrokeColor(nvg, strokeColor.toNVG())
      performStroke = true
    }

    nvgBeginPath(nvg)
    nvgMoveTo(nvg, Float(start.x), Float(start.y))
    nvgLineTo(nvg, Float(end.x), Float(end.y))
    
    if performFill {
      nvgFill(nvg)
    }
    if performStroke {
      nvgStroke(nvg)
    }
  }

  override open func drawRect(rect: DRect, paint: Paint) {
    var performFill = false
    var performStroke = false
    if let color = paint.color {
      nvgFillColor(nvg, color.toNVG())
      performFill = true
    }
    if let strokeWidth = paint.strokeWidth, let strokeColor = paint.strokeColor {
      nvgStrokeWidth(nvg, Float(strokeWidth))
      nvgStrokeColor(nvg, strokeColor.toNVG())
      performStroke = true
    }

    nvgBeginPath(nvg)
    nvgRect(
      nvg,
      Float(rect.min.x),
      Float(rect.min.y),
      Float(rect.size.width),
      Float(rect.size.height))

    if performFill {
      nvgFill(nvg)
    }
    if performStroke {
      nvgStroke(nvg)
    }
  }

  override open func drawCircle(center: DVec2, radius: Double, paint: Paint) {
    with(paint: paint) {
      nvgBeginPath(nvg)
      nvgCircle(nvg, Float(center.x), Float(center.y), Float(radius))
    }
  }

  override open func measureText(text: String, paint: TextPaint) -> DSize2 {
    applyFontConfig(paint.fontConfig)

    var bounds = [Float](repeating: 0, count: 4)

    if let breakWidth = paint.breakWidth {
        nvgTextBoxBounds(nvg, 0, 0, Float(breakWidth), text, nil, &bounds)
    } else {
        nvgTextBounds(nvg, 0, 0, text, nil, &bounds)
    }

    return DSize2(Double(bounds[2]), Double(bounds[3]))
  }

  override open func drawText(text: String, position: DVec2, paint: TextPaint) {
    nvgBeginPath(nvg)
    applyFontConfig(paint.fontConfig)
    if let color = paint.color {
      nvgFillColor(nvg, color.toNVG())
    }

    if let breakWidth = paint.breakWidth {
        nvgTextBox(nvg, Float(position.x), Float(position.y), Float(breakWidth), text, nil)
    } else {
        nvgText(nvg, Float(position.x), Float(position.y), text, nil)
    }
  }

  override public func drawImage(image: Image2, topLeft: DVec2) {
    let imageId = loadImageOrUpdate(image)

    let pattern = nvgImagePattern(nvg, Float(topLeft.x), Float(topLeft.y), Float(image.data.width), Float(image.data.height), 0, imageId, 1)
    nvgFillPaint(nvg, pattern)

    nvgBeginPath(nvg)
    nvgRect(
      nvg,
      Float(topLeft.x),
      Float(topLeft.y),
      Float(image.data.width),
      Float(image.data.height))

    nvgFill(nvg)
  }

  /// returns the id of the loaded image in NanoVG
  private func loadImageOrUpdate(_ image: Image2) -> Int32 {
    if let imageId = imageIds[image] {
      if image.invalid {
        nvgUpdateImage(nvg, imageId, image.data.getData())
      }
      return imageId
    }

    let imageId = nvgCreateImageRGBA(nvg, Int32(image.data.width), Int32(image.data.height), 0, image.data.getData())
    imageIds[image] = imageId
    image.invalid = false

    return imageId
  }

  private func applyFontConfig(_ config: FontConfig) {
    if fontIds[config.face.path] == nil {
      _ = loadFont(config.face.path)
    }
    nvgFontFaceId(nvg, fontIds[config.face.path]!)
    nvgFontSize(nvg, Float(config.size))
    nvgTextAlign(nvg, Int32(NVG_ALIGN_LEFT.rawValue | NVG_ALIGN_TOP.rawValue))
  }

  private func loadFont(_ path: String) -> Bool {
    let id = nvgCreateFont(nvg, path, path)
    if id > -1 {
        fontIds[path] = id
    }
    print("Loaded font from", path, id)
    return id > -1
  }

  override public func deactivate() {
    nvgEndFrame(nvg)
  }
}