import CXShim

protocol AnyStylePropertyProtocol: class {
  var definitionValue: StylePropertyValueDefinition.Value? { get set }
  var container: Widget? { get set }
  var name: String? { get set }
}

protocol StylePropertyProtocol: AnyStylePropertyProtocol {
  associatedtype Container: Widget
  associatedtype Value

  var concreteDefaultValue: Value { get }
  var defaultValue: StylePropertyValue<Value> { get }
  var styleValue: StylePropertyValue<Value>? { get set }
  var resolvedValue: Value { get set }

  var definitionValueSourceSubscription: AnyCancellable? { get set }
  var parentValueSubscription: AnyCancellable? { get set }
}

extension StylePropertyProtocol {
  func updateStyleValue() {
    definitionValueSourceSubscription?.cancel()

    if let definitionValue = definitionValue {
      switch definitionValue {
      case let .constant(value):
        styleValue = StylePropertyValue(value)!
      case let .reactive(publisher):
        definitionValueSourceSubscription = publisher.sink { [unowned self] in
          styleValue = StylePropertyValue($0)!
        }
      }
    } else {
      styleValue = nil
    }
  }

  func updateResolvedValue() {
    parentValueSubscription?.cancel()

    outerSwitch: switch styleValue ?? defaultValue {
    case .inherit:
      guard let container = container, let name = name else {
        resolvedValue = concreteDefaultValue
        //print("warning: tried to resolve .inherit style property before setup by widget")
        return
      }

      if let parent = container.parent as? Container {
        let mirror = Mirror(reflecting: parent)
        for child in mirror.allChildren {
          if child.label == name, let property = child.value as? AnyStyleProperty<Value> {
            resolvedValue = property.resolvedValue
            parentValueSubscription = property.publisher.sink { [unowned self] in
              resolvedValue = $0
            }
            break outerSwitch
          }
        }
      }

      resolvedValue = concreteDefaultValue

    case let .value(value):
      resolvedValue = value
    }
  }
}

public class AnyStyleProperty<V>: StylePropertyProtocol, InternalReactiveProperty {
  public typealias Container = Widget
  public typealias Value = V

  weak var container: Container? {
    didSet {
      if oldValue !== container {
        updateResolvedValue()
      }
    }
  }
  var name: String?

  var concreteDefaultValue: Value
  var defaultValue: StylePropertyValue<Value>

  lazy public private(set) var publisher = PropertyPublisher<Value>(getCurrentValue: { [weak self] in self?.value })

  var definitionValue: StylePropertyValueDefinition.Value? = nil {
    didSet {
      updateStyleValue()
    }
  }

  var styleValue: StylePropertyValue<Value>? = nil {
    didSet {
      updateResolvedValue()
    }
  }

  var resolvedValue: Value {
    didSet {
      notifyChange()
    }
  }

  var definitionValueSourceSubscription: AnyCancellable?
  var parentValueSubscription: AnyCancellable?

  public var value: Value {
    resolvedValue
  }

  public init(wrappedValue: Value, default defaultValue: StylePropertyValue<Value>? = nil) {
    self.concreteDefaultValue = wrappedValue
    self.defaultValue = defaultValue ?? .value(wrappedValue)
    self.styleValue = self.defaultValue
    self.resolvedValue = self.concreteDefaultValue
    self.updateResolvedValue()
  }
}

@propertyWrapper
public final class DefaultStyleProperty<V>: AnyStyleProperty<V> {
  public var wrappedValue: Value {
    get { resolvedValue }
  }
  
  public var projectedValue: DefaultStyleProperty<Value> {
    self
  }
}

@propertyWrapper
public final class AnySpecialStyleProperty<Container: Widget, V>: AnyStyleProperty<V> {
  public var wrappedValue: Value {
    get { resolvedValue }
  }
  
  public var projectedValue: AnySpecialStyleProperty<Container, Value> {
    self
  }
}