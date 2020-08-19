import VisualAppBase
import CustomGraphicsMath

public final class TextField: Widget, ConfigurableWidget {
    public struct Config: WidgetGUI.Config {
        public typealias PartialConfig = TextField.PartialConfig

        public var backgroundConfig: Background.PartialConfig
        public var textInputConfig: TextInput.PartialConfig

        public init(backgroundConfig: Background.PartialConfig, textInputConfig: TextInput.PartialConfig) {
            self.backgroundConfig = backgroundConfig
            self.textInputConfig = textInputConfig
        }
    }

    public struct PartialConfig: WidgetGUI.PartialConfig {
        public var backgroundConfig = Background.PartialConfig()
        public var textInputConfig = TextInput.PartialConfig()

        public init() {}
    }

    public static let defaultConfig = Config(
        backgroundConfig: Background.PartialConfig {
            $0.fill = .Blue
            $0.shape = .Rectangle
        },
        textInputConfig: TextInput.PartialConfig())

    public var localPartialConfig: PartialConfig?
    public var localConfig: Config?
    lazy public var config: Config = combineConfigs()

    lazy private var textInput = TextInput()

    public internal(set) var onTextChanged = EventHandlerManager<String>()
    
    public init(_ initialText: String = "", onTextChanged textChangedHandler: ((String) -> ())? = nil) {
        super.init()
        textInput.text = initialText
        if let handler = textChangedHandler {
            _ = onDestroy(onTextChanged(handler))
        }
    }

    override public func build() {
        _ = onDestroy(textInput.onTextChanged { [unowned self] in
            onTextChanged.invokeHandlers($0)
        })
        
        textInput.with(config: config.textInputConfig)

        children = [
            Background {
                Padding(all: 16) {
                    textInput
                }
            }.with(config: config.backgroundConfig)
        ]
    }

    override public func performLayout() {
        let child = children[0]
        child.constraints = constraints
        child.layout()
        bounds.size = child.bounds.size
    }
}