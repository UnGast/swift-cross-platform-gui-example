import VertexGUI

let app = try VertexGUI.Application()

let store: TodoStore = TodoStore()

try app.createWindow(widgetRoot: Root(rootWidget: Container().withContent {
    TodoAppView().with(styleProperties: {
        (\.$grow, 1)
        (\.$alignSelf, .stretch)
    })
}.provide(dependencies: store)))

do {
    try app.start()
} catch {
    print("Error while running app", error)
}
