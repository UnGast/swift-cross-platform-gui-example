import Foundation
import GfxMath
import SkiaKit
import Drawing
import Dispatch
import VisualAppBase
import Events

open class Root: Parent {
  open var bounds: DRect = DRect(min: DPoint2(0, 0), size: DSize2(0, 0)) {
    didSet {
      layout()
    }
  }
  /** example: scale 2.0 -> the size of the root widget is halved
  and all coordinates and sizes are scaled by two (from the top left corner)
  -> content will be twice the size (e.g. text, images, fixed size widgets) */
  public var scale = 1.0 {
    didSet {
      layout()
    }
  }

  open var globalPosition: DPoint2 {
    return bounds.min
  }

  public var rootWidget: Widget

  var widgetContext: WidgetContext? {
    didSet {
      if let widgetContext = widgetContext {
        widgetContext.debugLayout = debugLayout
      }
      rootWidget.context = widgetContext!
    }
  }
  /* Widget lifecycle managment
  --------------------------------
  */
  // TODO: implement getTick!
  lazy public private(set) var widgetLifecycleManager = Widget.LifecycleManager { Tick(deltaTime: 0, totalTime: 0) }
  public let widgetLifecycleBus = WidgetBus<WidgetLifecycleMessage>()

  lazy var treeManager = WidgetTreeManager(widgetContext: widgetContext!, widgetLifecycleBus: widgetLifecycleBus)
  lazy var styleManager = StyleManager()
  lazy var cumulatedValuesProcessor = CumulatedValuesProcessor(self)
  lazy var drawingManager = DrawingManager(rootWidget: rootWidget)
  /* end Widget lifecycle management */

  //private var focusContext = FocusContext()
  /* focus management
  --------------------------*/
  var focusManager = FocusManager()
  /* end focus management */

  /* event propagation
  ----------------------------
  */
  lazy private var mouseEventManager = WidgetTreeMouseEventManager(root: self)
  private var mouseMoveEventBurstLimiter = BurstLimiter(minDelay: 0.015)
  /* end event propagation */

  /* debugging
  --------------------------
  */
  public let debugManager = DebugManager()

  public var debugLayout = false {
    didSet {
      if let widgetContext = widgetContext {
        widgetContext.debugLayout = debugLayout
      }
    }
  }
  /* end debugging */

  public private(set) var destroyed = false
  private var onDestroy = EventHandlerManager<Void>()

  public init(rootWidget contentRootWidget: Widget) {
    self.rootWidget = contentRootWidget
  }
  
  open func setup(
    measureText: @escaping (_ text: String, _ paint: TextPaint) -> DSize2,
    getKeyStates: @escaping () -> KeyStatesContainer,
    getApplicationTime: @escaping () -> Double,
    getRealFps: @escaping () -> Double,
    requestCursor: @escaping (_ cursor: Cursor) -> () -> Void
  ) {
    self.widgetContext = WidgetContext(
      measureText: measureText,
      getKeyStates: getKeyStates,
      getApplicationTime: getApplicationTime,
      getRealFps: getRealFps,
      requestCursor: requestCursor,
      queueLifecycleMethodInvocation: { [unowned self] in widgetLifecycleManager.queue($0, target: $1, sender: $2, reason: $3) },
      focusManager: focusManager
    )

    treeManager.mountAsRoot(widget: rootWidget, root: self)
    treeManager.buildSubTree(rootWidget: rootWidget)
    styleManager.processTree(rootWidget)
  }
  
  open func layout() {
    rootWidget.layout(constraints: BoxConstraints(size: bounds.size / scale))
    cumulatedValuesProcessor.resolveSubTree(rootWidget: rootWidget)
  }

  /** - Returns: whether the event was consumed (true) or fell through (false) */
  final public func receive(rawPointerEvent: RawMouseEvent) -> Bool {
   if let event = rawPointerEvent as? RawMouseMoveEvent {

      mouseMoveEventBurstLimiter.limit { [weak self] in
        if let self = self {
          var operation = ProcessMouseEventOperationDebugData()
          operation.recordStart()

          self.mouseEventManager.propagate(rawPointerEvent)

          operation.recordEnd()
          self.debugManager.data.storeOperation(operation)
        }
      }

    } else {
      var operation = ProcessMouseEventOperationDebugData()
      operation.recordStart()

      mouseEventManager.propagate(rawPointerEvent)

      operation.recordEnd()
      self.debugManager.data.storeOperation(operation)
    }

    return false
  }

  @discardableResult
  open func consume(_ rawKeyEvent: KeyEvent) -> Bool {
    var operation = ProcessKeyEventOperationDebugData()
    operation.recordStart()
    propagate(rawKeyEvent)
    operation.recordEnd()
    debugManager.data.storeOperation(operation)
    return false
  }

  @discardableResult
  open func consume(_ rawTextEvent: TextEvent) -> Bool {
    var operation = ProcessTextEventOperationDebugData()
    operation.recordStart()
    propagate(rawTextEvent)
    operation.recordEnd()
    debugManager.data.storeOperation(operation)
    return false
  }

  open func tick(_ tick: Tick) {
    var operation = TickOperationDebugData()
    operation.recordStart()

    widgetContext!.onTick.invokeHandlers(tick)

    var stepData = runTickStep {
      let buildQueue = widgetLifecycleManager.queues[.build]!
      var iterator = buildQueue.iterate()
      while let entry = iterator.next() {
        if !entry.target.destroyed {
          treeManager.buildChildren(of: entry.target)
        }
      }
      buildQueue.clear()
    }
    operation.storeStep(.build, data: stepData)

    stepData = runTickStep {
      var iterator = widgetLifecycleManager.queues[.updateChildren]!.iterate()
      while let queueEntry = iterator.next() {
        treeManager.updateChildren(of: queueEntry.target)
      }
      widgetLifecycleManager.queues[.updateChildren]!.clear()
    }
    operation.storeStep(.updateChildren, data: stepData)

    // TODO: check whether any parent of the widget was already processed (which automatically leads to a reprocessing of the styles)
    // TODO: or rather follow the pattern of invalidate...()? --> invalidateStyle()
    stepData = runTickStep {
      let matchedStylesQueue = widgetLifecycleManager.queues[.updateMatchedStyles]!
      var iterator = matchedStylesQueue.iterateSubTreeRoots()
      while let entry = iterator.next() {
        if !entry.target.destroyed && entry.target.mounted {
          styleManager.processTree(entry.target)
        }
      }
      matchedStylesQueue.clear()
    }
    operation.storeStep(.resolveMatchedStyles, data: stepData)

    stepData = runTickStep {
      let stylePropertiesQueue = widgetLifecycleManager.queues[.resolveStyleProperties]!
      var iterator = stylePropertiesQueue.iterate()
      while let entry = iterator.next() {
        if !entry.target.destroyed && entry.target.mounted {
          entry.target.resolveStyleProperties()
        }
      }
      stylePropertiesQueue.clear()
    }
    operation.storeStep(.resolveStyleProperties, data: stepData)

    stepData = runTickStep {
      let layoutQueue = widgetLifecycleManager.queues[.layout]!
      //print("LAYOUT COUNT", layoutQueue.entries.count)
      let layoutIterator = layoutQueue.iterate()
      while let entry = layoutIterator.next() {
        // the widget should only be relayouted if it hasn't been layouted before
        // if it hasn't been layouted before it will be layouted during
        // the first layout pass started by rootWidget.layout()
        if entry.target.layouted && !entry.target.destroyed {
          entry.target.layout(constraints: entry.target.referenceConstraints ?? entry.target.previousConstraints!)
        }
      }
      //print("LAYOUT COUNT AFTER", layoutQueue.entries.count)
      layoutQueue.clear()
    }
    operation.storeStep(.layout, data: stepData)

    stepData = runTickStep {
      cumulatedValuesProcessor.processQueue()
    }
    operation.storeStep(.updateCumulatedValues, data: stepData)

    operation.recordEnd()
    debugManager.data.storeOperation(operation)
  }

  func runTickStep(block: () -> ()) -> TickOperationStepDebugData {
    var stepData = TickOperationStepDebugData()
    stepData.recordStart()
    block()
    stepData.recordEnd()
    return stepData
  }

  open func draw(_ drawingContext: DrawingContext, canvas: SkiaKit.Canvas) {
    var operation = DrawOperationDebugData()
    operation.recordStart()

    let rootDrawingContext = drawingContext.clone()
    // this scaling is the last transform that should be executed
    rootDrawingContext.transform(.scale(DVec2(scale, scale)))
    rootDrawingContext.lock()

    drawingManager.processQueue(widgetLifecycleManager.queues[.draw]!, drawingContext: rootDrawingContext, canvas: canvas)
    widgetLifecycleManager.queues[.draw]?.clear()

    operation.recordEnd()
    debugManager.data.storeOperation(operation)
  }

  /*
    Event Propagation
    --------------------
    */
  internal func propagate(_ rawKeyEvent: KeyEvent) {
    var next = Optional(rootWidget)
    while let current = next {
      if let keyDownEvent = rawKeyEvent as? KeyDownEvent {
        current.processKeyEvent(
          GUIKeyDownEvent(
            key: keyDownEvent.key,
            keyStates: keyDownEvent.keyStates,
            repetition: keyDownEvent.repetition))
      } else if let keyUpEvent = rawKeyEvent as? KeyUpEvent {
        current.processKeyEvent(
          GUIKeyUpEvent(
            key: keyUpEvent.key,
            keyStates: keyUpEvent.keyStates,
            repetition: keyUpEvent.repetition))
      } else {
        fatalError("Unsupported event type: \(rawKeyEvent)")
      }
      
      next = nil
      for child in current.children {
        if child.focused {
          next = child
          break
        }
      }
    }
  }

  internal func propagate(_ event: TextEvent) {
    var next = Optional(rootWidget)
    while let current = next {
      if let event = event as? TextInputEvent {
        current.processTextEvent(GUITextInputEvent(event.text))
      }

      next = nil
      for child in current.children {
        if child.focused {
          next = child
          break
        }
      }
    }
  }
  /*
  End Event Propagation
  ----------------------
  */

  open func destroy() {
    if destroyed {
      return
    }
    rootWidget.destroy()
    onDestroy.invokeHandlers(())
  }

  deinit {
    print("DEINITIALIZED ROOT")
    destroy()
  }
}

extension Root {
  class WidgetBuffer: Collection {
    typealias Index = Int
    typealias Element = Widget

    var widgets: [Widget] = []

    init() {}

    var count: Int {
      widgets.count
    }
 
    var startIndex: Int = 0

    var endIndex: Int {
      startIndex + count
    }

    subscript(position: Int) -> Widget {
      widgets[position]
    }

    func index(after i: Int) -> Int {
      i + 1
    }
    
    func makeIterator() -> WidgetBufferIterator {
      WidgetBufferIterator(self)
    }

    func append(_ widget: Widget) {
      widgets.append(widget)
    }

    func clear() {
      widgets = []
    }
  }

  struct WidgetBufferIterator: IteratorProtocol {
    var buffer: WidgetBuffer
    var nextIndex = 0

    init(_ buffer: WidgetBuffer) {
      self.buffer = buffer
    }
    
    mutating func next() -> Widget? {
      if buffer.widgets.count == nextIndex {
        return nil
      } else {
        defer { nextIndex += 1 }
        return buffer.widgets[nextIndex]
      }
    }
  }

  /**
  // TODO: maybe rename to DebugDataCollector */
  public class DebugManager {
    public var data = DebugData()

    public init() {}
  }

  public struct DebugData {
    public var operations: [RootOperationDebugData] = []

    mutating public func storeOperation(_ operation: RootOperationDebugData) {
      operations.append(operation)
    }
  }
}

public protocol RootOperationDebugData {
  var startTime: Double { get set }
  var endTime: Double { get set }
  var duration: Double { get }

  mutating func recordStart()
  mutating func recordEnd()
}

extension RootOperationDebugData {
  public var duration: Double {
    endTime - startTime
  }

  mutating public func recordStart() {
    startTime = Date.timeIntervalSinceReferenceDate
  }

  mutating public func recordEnd() {
    endTime = Date.timeIntervalSinceReferenceDate
  }
}

extension Root {
  public struct ProcessMouseEventOperationDebugData: RootOperationDebugData {
    public var startTime: Double = 0
    public var endTime: Double = 0

    public init() {}
  }
  
  public struct ProcessKeyEventOperationDebugData: RootOperationDebugData {
    public var startTime: Double = 0
    public var endTime: Double = 0

    public init() {}
  }

 public struct ProcessTextEventOperationDebugData: RootOperationDebugData {
    public var startTime: Double = 0
    public var endTime: Double = 0

    public init() {}
  }

  public struct TickOperationDebugData: RootOperationDebugData {
    public var startTime: Double = 0
    public var endTime: Double = 0
    public var steps: [TickOperationStep: TickOperationStepDebugData] = [:]

    public init() {}

    mutating public func storeStep(_ step: TickOperationStep, data: TickOperationStepDebugData) {
      steps[step] = data
    }
  }

  public enum TickOperationStep {
    case build
    case updateChildren
    case resolveMatchedStyles
    case resolveStyleProperties
    case layout
    case updateCumulatedValues 
  }

  public struct TickOperationStepDebugData: RootOperationDebugData {
    public var startTime: Double = 0
    public var endTime: Double = 0

    public init() {}
  }

  public struct DrawOperationDebugData: RootOperationDebugData {
    public var startTime: Double = 0
    public var endTime: Double = 0

    public init() {}
  }
}