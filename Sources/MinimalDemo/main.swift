import VertexGUI

public class MinimalDemoApp: WidgetsApp {
  public init() {
    super.init(baseApp: SDL2OpenGL3NanoVGVisualApp())
  }

  override open func setup() {
    let guiRoot = WidgetGUI.Root(rootWidget: MainView())
    _ = createWindow(guiRoot: guiRoot, options: Window.Options(background: Color(20, 36, 50, 255)), immediate: true)
  }
}

let app = MinimalDemoApp()

do {
  try app.start()
} catch {
  print("an error occurred while running the app:", error)
}