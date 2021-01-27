import GfxMath
import VisualAppBase

extension Experimental {
  public class Button: ComposedWidget, ExperimentalStylableWidget, GUIMouseEventConsumer {
    private let childBuilder: SingleChildContentBuilder.ChildBuilder

    public let onClick = WidgetEventHandlerManager<Void>()

    private var hovered: Bool = false {
      didSet {
        notifySelectorChanged()
      }
    }
    override public var pseudoClasses: [String] {
      hovered ? ["hover"] : []
    }

    override public var experimentalSupportedStyleProperties: Experimental.StylePropertySupportDefinitions {
      Experimental.StylePropertySupportDefinitions {
        (StyleKeys.padding, type: .specific(Insets.self))
        (StyleKeys.backgroundFill, type: .specific(Color.self))
      }
    }

    public init(
      classes: [String]? = nil,
      @Experimental.StylePropertiesBuilder styleProperties stylePropertiesBuilder: (StyleKeys.Type) -> Experimental.StyleProperties = { _ in [] },
      @SingleChildContentBuilder content contentBuilder: @escaping () -> SingleChildContentBuilder.Result,
      onClick onClickHandler: (() -> ())? = nil) {
        let result = contentBuilder()
        self.childBuilder = result.child
        super.init()
        self.experimentalProvidedStyles.append(contentsOf: result.experimentalStyles)
        if let handler = onClickHandler {
          self.onClick.addHandler(handler)
        }
        if let classes = classes {
          self.classes = classes
        }
        self.with(stylePropertiesBuilder(StyleKeys.self))
    }

    override public func performBuild() {
      rootChild = Experimental.Container(styleProperties: {
        ($0.padding, stylePropertyValue(reactive: StyleKeys.padding))
        ($0.backgroundFill, stylePropertyValue(reactive: StyleKeys.backgroundFill))
      }) { [unowned self] in
        childBuilder()
      }
    }

    override public func renderContent() -> RenderObject? {
      return super.renderContent()
    }

    public func consume(_ event: GUIMouseEvent) {
      if let _ = event as? GUIMouseButtonClickEvent {
        onClick.invokeHandlers()
      } else if let _ = event as? GUIMouseEnterEvent {
        hovered = true
      } else if let _ = event as? GUIMouseLeaveEvent {
        hovered = false
      }
    }

    public enum StyleKeys: String, StyleKey, ExperimentalDefaultStyleKeys {
      case backgroundFill
      case padding
    }
  }
}