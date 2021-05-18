import VertexGUI

let app = try VertexGUI.Application()

try app.createWindow(widgetRoot: WidgetGUI.Root(rootWidget: Container().withContent {
  MainView().with(styleProperties: {
    (\.$alignSelf, .stretch)
    (\.$grow, 1)
  })
}))

do {
  try app.start()
} catch {
  print("Error while running the app", error)
}