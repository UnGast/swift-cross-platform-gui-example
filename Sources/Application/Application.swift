import Foundation
import CoreFoundation
import WidgetGUI
import HID
import VisualAppBase
import Drawing
import DrawingImplGL3NanoVG
import GfxMath
import GL
import SkiaKit
import CSkia

open class Application {
  private var windowBunches: [WindowBunch] = []

  private var event = Event()

  public init() throws {
    Platform.initialize()
    print("Platform version: \(Platform.version)")
  }

  public func createWindow(widgetRoot: Root) throws {

    // either use a custom surface sub-class
    // or use the default implementation directly
    // let surface = CPUSurface()
    let window = try Window(properties: WindowProperties(title: "Title", frame: .init(0, 0, 800, 600)),
                            surface: { try OpenGLWindowSurface(in: $0, with: ()) })

    try window.setupSurface()

    guard let surface = window.surface as? OpenGLWindowSurface else {
        fatalError("no window surface")
    }

    surface.glContext.makeCurrent()

    let canvas = getCanvas(for: surface)

    let drawingBackend = MockDrawingBackend() //GL3NanoVGDrawingBackend(surface: surface)

    let windowBunch = WindowBunch(window: window, widgetRoot: widgetRoot, drawingContext: DrawingContext(backend: drawingBackend), canvas: canvas)

    widgetRoot.setup(
      measureText: { [unowned drawingBackend] text, paint in drawingBackend.measureText(text: text, paint: paint) },
      getKeyStates:  { KeyStatesContainer() },
      getApplicationTime: { 0 },
      getRealFps: { 0 },
      requestCursor: { _ in { () } }
    )

    updateWindowBunchSize(windowBunch)

    self.windowBunches.append(windowBunch)
  }

  public func start() throws {
    DispatchQueue.main.async { [unowned self] in
      mainLoop()
    }
    dispatchMain()
  }

  private func mainLoop() {
    var quit = false

    Events.pumpEvents()

    while Events.pollEvent(&event) {
      switch event.variant {
        case .userQuit:
          quit = true
        case .window:
          if case let .resizedTo(newSize) = event.window.action {
            if let windowBunch = findWindowBunch(windowId: event.window.windowID) {
              updateWindowBunchSize(windowBunch)
            }
          }
        case .textInput:
          print("text input", event.textInput)
        case .textEditing:
          print("text editing", event.textEditing)
        default:
          forwardEvent(event: event)
      }
    }
      
    performNextTickAndFrame()

    if quit {
      Platform.quit()
    } else {
      DispatchQueue.main.async { [unowned self] in
        mainLoop()
      }
    }
  }

  private func forwardEvent(event: Event) {
    switch event.variant {
      case .pointerMotion:
        let eventData = event.pointerMotion
        if let windowBunch = findWindowBunch(windowId: eventData.windowID) {
          let currentPosition = DVec2(eventData.x, eventData.y)
          let delta = DVec2(eventData.deltaX, eventData.deltaY)
          windowBunch.widgetRoot.receive(rawPointerEvent: RawMouseMoveEvent(position: currentPosition, previousPosition: currentPosition - delta))
        }
      
      case .pointerButton:
        let eventData = event.pointerButton

        if let mappedButton = mapPointerButton(eventData.button), let windowBunch = findWindowBunch(windowId: eventData.windowID) {
          let currentPosition = DVec2(eventData.x, eventData.y)

          switch eventData.state {
            case .pressed:
              windowBunch.widgetRoot.receive(rawPointerEvent: RawMouseButtonDownEvent(button: mappedButton, position: currentPosition))
            case .released:
              windowBunch.widgetRoot.receive(rawPointerEvent: RawMouseButtonUpEvent(button: mappedButton, position: currentPosition))
          }
        }
      
      case .pointerScroll:
        let eventData = event.pointerScroll

        if let windowBunch = findWindowBunch(windowId: eventData.windowID) {
          let currentPosition = DVec2(eventData.x, eventData.y)
          windowBunch.widgetRoot.receive(rawPointerEvent: RawMouseWheelEvent(scrollAmount: DVec2(Double(eventData.horizontal), Double(eventData.vertical)), position: currentPosition))
        }

      default:
        break
    }
  }

  private func mapPointerButton(_ button: HID.PointerButton) -> MouseButton? {
    switch button {
    case .left:
      return .Left
    case .right:
      return .Right
    default:
      return nil
    }
  }

  private func performNextTickAndFrame() {
    for bunch in windowBunches {
      if let surface = bunch.window.surface as? SDLOpenGLWindowSurface {
        surface.glContext.makeCurrent()
      }

      let drawableSize = bunch.window.surface!.getDrawableSize()
      glViewport(0, 0, GLMap.Size(drawableSize.width), GLMap.Size(drawableSize.height))
      glClearColor(1, 1, 1, 1)
      glClear(GLMap.COLOR_BUFFER_BIT)

      bunch.widgetRoot.tick(Tick(deltaTime: 0, totalTime: 0))

      bunch.canvas.clear()
      
     // bunch.drawingContext.backend.activate()
      bunch.widgetRoot.draw(bunch.drawingContext, canvas: bunch.canvas)
      //bunch.drawingContext.backend.deactivate()

      bunch.canvas.flush()

      if let surface = bunch.window.surface as? SDLOpenGLWindowSurface {
        surface.swap()
      }
    }
  }

  private func updateWindowBunchSize(_ windowBunch: WindowBunch) {
    guard let surface = windowBunch.window.surface as? SDLOpenGLWindowSurface else {
      fatalError("window must have a surface")
    }
    surface.glContext.makeCurrent()
    windowBunch.canvas = getCanvas(for: surface)
    let drawableSize = surface.getDrawableSize()
    windowBunch.widgetRoot.bounds.size = DSize2(Double(drawableSize.width), Double(drawableSize.height))
  }

  private func getCanvas(for surface: OpenGLWindowSurface) -> Canvas {
    let surfaceSize = surface.getDrawableSize()

    var buffer: GLMap.Int = 0
    glGetIntegerv(GLMap.DRAW_FRAMEBUFFER_BINDING, &buffer);

    let skiaSurface = SkiaKit.Surface(handle: makeSurface(Int32(surfaceSize.width), Int32(surfaceSize.height), buffer))

    return skiaSurface.canvas
  }

  private func findWindowBunch(windowId: Int) -> WindowBunch? {
    windowBunches.first { $0.window.windowID == windowId }
  }
}

extension Application {
  public class WindowBunch {
    public var window: HID.Window
    public var widgetRoot: Root
    public var drawingContext: DrawingContext
    public var canvas: SkiaKit.Canvas

    public init(window: HID.Window, widgetRoot: Root, drawingContext: DrawingContext, canvas: SkiaKit.Canvas) {
      self.window = window
      self.widgetRoot = widgetRoot
      self.drawingContext = drawingContext
      self.canvas = canvas
    }
  }
}