import GfxMath

/// A DrawingContext provides functions to draw graphics primitves. 
/// It forwards draw calls to a platform-specific rendering
/// backend.
///
/// The currently supported primitives are:
/// - line
/// - rectangle
/// - circle
///
/// Furthermore operations such as clipping everything outside
/// a certain area, measuring rendered text size and transformations
/// are supported.
///
/// Before you start to perform drawing operations,
/// call `.beginDrawing()` which runs some backend
/// specific setup code.
/// After you finished drawing, call `.endDrawing()`.
///
/// **Note:** `.beginDrawing()` and `.endDrawing()` are automatically
/// called on the context that is passed to a LeafWidget's `.draw()` method.
/// You should not call these methods in your `.draw()` implementation.
open class DrawingContext {
  public let backend: DrawingBackend 

  public private(set) var inherentTransforms: [DTransform2] = []
  public private(set) var inherentOpacity: Double = 1
  public private(set) var inherentClip: DRect?
  private var transforms: [DTransform2] = []
  public var opacity: Double = 1 {
    willSet {
      checkFailOpacity(newValue)
    }
  }
  private var currentClip: DRect?
  public var mergedTransforms: [DTransform2] {
    inherentTransforms + transforms
  }
  public var mergedOpacity: Double {
    inherentOpacity * opacity
  }
  public var mergedClip: DRect? {
    if let currentClip = currentClip, let inherentClip = inherentClip {
      return currentClip.intersection(with: inherentClip)
    } 
    return currentClip ?? inherentClip
  }

  public init(backend: DrawingBackend) {
    self.backend = backend 
  }

  public func clone() -> DrawingContext {
    let result = DrawingContext(backend: backend)
    result.inherentTransforms = inherentTransforms
    result.inherentOpacity = inherentOpacity
    result.inherentClip = inherentClip
    result.transforms = transforms
    result.opacity = opacity
    result.currentClip = currentClip
    return result
  }

  open func lock() {
    self.inherentTransforms = mergedTransforms
    self.transforms = []
    self.inherentOpacity = mergedOpacity
    self.opacity = 1
    self.inherentClip = mergedClip
    self.currentClip = nil
  }

  private func checkFailOpacity(_ opacity: Double) {
    if opacity < 0 || opacity > 1 {
      fatalError("opacity must be between (including) 0 and 1")
    }
  }

  open func beginDrawing() {
    backend.activate()
    if let clip = mergedClip {
      backend.clip(rect: clip)
    } else {
      backend.resetClip()
    }
  }

  private func preprocess(_ point: DVec2) -> DVec2 {
    mergedTransforms.transform(point: point)
  }

  private func preprocess(_ size: DSize2) -> DSize2 {
    mergedTransforms.transform(size: size)
  }

  public func preprocess(_ rect: DRect) -> DRect {
    let min = preprocess(rect.min)
    let max = preprocess(rect.max)
    return DRect(min: min, max: max)
  }

  private func preprocess(_ paint: Paint) -> Paint {
    var processed = paint
    if let color = paint.color {
      processed.color = color.adjusted(alpha: UInt8(mergedOpacity * color.aFrac * 255))
    }
    if let strokeColor = paint.strokeColor {
      processed.strokeColor = strokeColor.adjusted(alpha: UInt8(mergedOpacity * strokeColor.aFrac * 255))
    }
    return processed
  }

  private func preprocess(_ paint: TextPaint) -> TextPaint {
    var processed = paint
    if let color = paint.color {
      processed.color = color.adjusted(alpha: UInt8(mergedOpacity * color.aFrac * 255))
    }
    processed.fontConfig.size = preprocess(DSize2(0, processed.fontConfig.size)).height
    return processed
  }

  /**
  Appends a transform to the list of transforms.

  The new transform will be the first to be applied to any position.
  */
  public func transform(_ transform: DTransform2) {
    self.transforms.append(transform)
  }

  /**
  Appends transforms to the list of transforms.

  The last transform in the list will be the first one to be applied to any position.
  */
  public func transform(_ transforms: [DTransform2]) {
    self.transforms.append(contentsOf: transforms)
  }

  /**
  Limit the area in which graphics primitives are drawn.

  Everything outside of the given rectangle will be clipped.

  Multiple `.clip()` calls can be made. The result clip mask
  will be the intersection of the previous clip mask with the new one.
  */
  public func clip(rect: DRect) {
    let preprocessedRect = preprocess(rect)
    if let currentClip = currentClip {
      self.currentClip = currentClip.intersection(with: preprocessedRect)
    } else {
      self.currentClip = preprocessedRect
    }
    backend.clip(rect: mergedClip ?? DRect(min: .zero, size: .zero))
  }

  /**
  Reset the clip state to the state the DrawingContext was created with.
  */
  public func resetClip() {
    self.currentClip = nil
    if let mergedClip = mergedClip {
      backend.clip(rect: mergedClip)
    } else {
      backend.resetClip()
    }
  }
  
  /**
  Draw a straight 2D line.

  Only `paint.strokeWidth` and `paint.strokeColor` apply.

  The `paint.strokeWidth` must be > 0 otherwise, nothing will be drawn.
  */
  public func drawLine(from start: DVec2, to end: DVec2, paint: Paint) {
    backend.drawLine(from: preprocess(start), to: preprocess(end), paint: preprocess(paint))
  }

  /**
  Draw a 2D rectangle.

  You can provide a `paint.color` to fill the rectangle.

  Additionally a `paint.strokeWidth` and `paint.strokeColor` can be provided
  to draw a border.

  `paint.color` can be omitted in order to draw only the border.
  */
  public func drawRect(rect: DRect, paint: Paint) {
    backend.drawRect(rect: preprocess(rect), paint: preprocess(paint))
  }

  /**
  Draw a 2D circle.

  See `drawRect` for the effect which the different `paint` properties have.
  */
  public func drawCircle(center: DVec2, radius: Double, paint: Paint) {
    backend.drawCircle(center: preprocess(center), radius: radius, paint: paint)
  }

  open func drawRoundedRect() {

  }

  open func drawPath() {
    
  }

  open func drawImage(image: Image2, topLeft: DVec2) {
    backend.drawImage(image: image, topLeft: topLeft)
  }

  /**
  Measure the width and height a certain text would have if drawn with
  the given paint. Used for calculating Widget layouts.

  `paint.color` may be ommited as it does not influence the size of text.
  */
  public func measureText(text: String, paint: TextPaint) -> DSize2 {
    backend.measureText(text: text, paint: preprocess(paint))
  }

  /**
  Draw a text.

  - Parameter position: top left corner of the drawn text
  */
  public func drawText(text: String, position: DVec2, paint: TextPaint) {
    backend.drawText(text: text, position: preprocess(position), paint: preprocess(paint))
  }

  open func endDrawing() {
    backend.deactivate()
  }
}