import Foundation
import CustomGraphicsMath
import VisualAppBase

public final class TextInput: Widget, StatefulWidget, ConfigurableWidget, GUIMouseEventConsumer, GUIKeyEventConsumer, GUITextEventConsumer {
    public struct Config: WidgetGUI.Config {
        public typealias PartialConfig = TextInput.PartialConfig

        public var textConfig: Text.PartialConfig
        public var caretColor: Color
        
        public init(textConfig: Text.PartialConfig, caretColor: Color) {
            self.textConfig = textConfig
            self.caretColor = caretColor
        }

        /*public init(partial partialConfig: PartialConfig?, default defaultConfig: Config) {
            self.textConfig = Text.PartialConfig.merged(partials: [partialConfig?.textConfig, defaultConfig.textConfig].compactMap { $0 })
            self.caretColor = partialConfig?.caretColor ?? defaultConfig.caretColor
        }*/
    }

    public struct PartialConfig: WidgetGUI.PartialConfig {
        public var textConfig: Text.PartialConfig? = Text.PartialConfig()
        public var caretColor: Color? = nil

        public init() {}

        public init(textConfig: Text.PartialConfig? = Text.PartialConfig(), caretColor: Color? = nil) {
            self.textConfig = textConfig
            self.caretColor = caretColor
        }
    }

    public static let defaultConfig = Config(
        textConfig: Text.PartialConfig(fontConfig: PartialFontConfig(size: 24)),
        caretColor: Color(80, 255, 240, 255))
    
    public struct State {
        public var caretBlinkStartTimestamp: Double = Date.timeIntervalSinceReferenceDate
    }

    public var localPartialConfig: PartialConfig?
    public var localConfig: Config?
    lazy public var config: Config = combineConfigs()

    public var state = State()
    
    public internal(set) var text: String

    private var caretPosition: Int = 0

    lazy private var textWidget = Text(text).with(config: config.textConfig)

    public internal(set) var onTextChanged = EventHandlerManager<String>()

    private var dropCursorRequest: (() -> ())?

    public init(_ initialText: String = "") {
        self.text = initialText
        super.init()
        self.focusable = true
    }

    public convenience init(_ initialText: String = "", caretColor: Color) {
        self.init(initialText)
        with(config: PartialConfig(caretColor: caretColor))
    }

    override public func build() {
        textWidget.text = text
        children = [textWidget]
    }

    override public func performLayout() {
        textWidget.constraints = BoxConstraints(
            minSize: constraints!.constrain(DSize2(50, constraints!.minHeight)),
            maxSize: constraints!.maxSize)
        textWidget.layout()
        bounds.size = textWidget.bounds.size
    }

    private func syncText() {
        textWidget.text = text
        onTextChanged.invokeHandlers(text)
    }

    public func consume(_ event: GUIMouseEvent) {
        if event is GUIMouseButtonClickEvent {
            requestFocus()

            if focused {
                let localX = event.position.x - textWidget.globalPosition.x
                
                var maxIndexBelowX = 0

                var previousBounds = DRect(min: .zero, size: .zero)

                for i in 0..<text.count {
                    let bounds = textWidget.getSubBounds(to: i + 1)
                    let letterBounds = DRect(min: previousBounds.max, max: bounds.max)
                    previousBounds = bounds

                    if localX > letterBounds.min.x + letterBounds.size.width / 2 {
                        maxIndexBelowX = i + 1
                    } else {
                        break
                    }
                }

                caretPosition = maxIndexBelowX
                
                invalidateRenderState()
            }
        } else if event is GUIMouseEnterEvent {
            dropCursorRequest = context!.requestCursor(.Text)
        } else if event is GUIMouseLeaveEvent {
            if let drop = dropCursorRequest {
                drop()
            }
        }
    }

    public func consume(_ event: GUIKeyEvent) {
        if let event = event as? GUIKeyDownEvent {
            switch event.key {
            case .Backspace:
                if caretPosition > 0 && text.count >= caretPosition {
                    invalidateRenderState {
                        text.remove(at: text.index(text.startIndex, offsetBy: caretPosition - 1))
                        caretPosition -= 1
                        syncText()
                    }
                }
            case .Delete:
                if caretPosition < text.count {
                    invalidateRenderState {
                        text.remove(at: text.index(text.startIndex, offsetBy: caretPosition))
                        syncText()
                    }
                }
            default:
                break
            }
        }
    }

    public func consume(_ event: GUITextEvent) {
        if let event = event as? GUITextInputEvent {
            invalidateRenderState {
                text.insert(contentsOf: event.text, at: text.index(text.startIndex, offsetBy: caretPosition))
                caretPosition += event.text.count
                syncText()
            }
        }
    }

    override public func renderContent() -> RenderObject? {
        let preCaretBounds = textWidget.getSubBounds(to: caretPosition)
        let caretSize = DSize2(textWidget.config.fontConfig.size * 0.1, globalBounds.size.height)
        let caretBounds = DRect(min: globalBounds.min + DVec2(preCaretBounds.max.x, 0), size: caretSize)

        return RenderObject.Container { [unowned self] in
            if focused {
                RenderObject.RenderStyle(
                    fillColor: TimedRenderValue(
                        id: 0, 
                        startTimestamp: Date.timeIntervalSinceReferenceDate, 
                        duration: 1, 
                        repetitions: 0) {
                            let alphaFactor = max(0, min(1, 6 * pow($0 - 0.5, 2) - 0.2))
                            return config.caretColor.adjusted(alpha: UInt8(255 * alphaFactor)) 
                    }) {
                        RenderObject.Rectangle(caretBounds)
                    }
            }

            textWidget.render()
        }
    }

    override public func destroySelf() {
        onTextChanged.removeAllHandlers()
        if let drop = dropCursorRequest {
            drop()
        }
    }
}