import Foundation
import VisualAppBase
import GfxMath

extension DeveloperTools {
  public class MainView: ContentfulWidget {
    private let inspectedRoot: Root

    private let store = DeveloperTools.Store()

    /*private var messages = WidgetBus<WidgetInspectionMessage>.MessageBuffer()
    private var widgetLifecycleMethodInvocationSignalBuffer = Bus<Widget.LifecycleMethodInvocationSignal>.MessageBuffer()
    @MutableProperty
    private var widgetLifecycleMethodInvocationSignalGroups: [Int: Widget.LifecycleMethodInvocationSignalGroup] = [:]*/

    public init(_ inspectedRoot: Root) {
      self.inspectedRoot = inspectedRoot

      /*_ = onDestroy(self.inspectedRoot.widgetContext!.inspectionBus.pipe(into: messages))

      self.inspectedRoot.widgetContext!.lifecycleMethodInvocationSignalBus.pipe(widgetLifecycleMethodInvocationSignalBuffer)

      _ = onDestroy(widgetLifecycleMethodInvocationSignalBuffer.onMessageAdded { [unowned self] in
        if (widgetLifecycleMethodInvocationSignalGroups[$0.invocationId] == nil) {
          widgetLifecycleMethodInvocationSignalGroups[$0.invocationId] = Widget.LifecycleMethodInvocationSignalGroup(
            method: $0.method, invocationId: $0.invocationId, signals: [$0])
        } else {
          widgetLifecycleMethodInvocationSignalGroups[$0.invocationId]!.signals.append($0)
        }
      })*/
    }

    @DirectContentBuilder override public var content: DirectContent {
      /*Container().with(styleProperties: {
        (\.$direction, .column)
        (\.$alignContent, .stretch)
        (\.$overflowY, .scroll)
      }).withContent { [unowned self] in
        buildMenu()
        buildActiveView()
      }.provide(dependencies: store, inspectedRoot)*/
      Container()
    }

    func buildMenu() -> Widget {
      Container().withContent {
        MainRoute.allCases.map {
          buildMenuItem($0)
        }
      }
    }

    func buildMenuItem(_ route: MainRoute) -> Widget {
      Container().with(classes: ["menu-item"]).onClick { [unowned self] in
        store.commit(.setActiveMainRoute(route))
      }.withContent {
        Text(route.rawValue)
      }
    }

    @DirectContentBuilder func buildActiveView() -> DirectContent {
      /*Dynamic(store.$state.activateMainRoute) { [unowned self] in
        switch store.state.activateMainRoute {
        case .inspector:
          DeveloperTools.InspectorView()
        case .performance:
          DeveloperTools.PerformanceView()
        }
      }*/
      Container()
    }

    override public var style: Style {
      Style("&") {
        (\.$background, theme.backgroundColor)
        (\.$foreground, theme.textColorOnBackground)
      } nested: {
        Style(".menu-item") {
          (\.$background, theme.primaryColor)
          (\.$fontWeight, .bold)
          (\.$padding, Insets(all: 16))
        } nested: {
          Style("&:hover") {
            (\.$background, theme.primaryColor.darkened(30))
          }
        }

        theme.styles
      }
    }
  }
}