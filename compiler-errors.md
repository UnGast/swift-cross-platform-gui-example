## 5.3.1 RELEASE

```swift
public enum AnyStylePropertyValue {
  case inherit
  case value(Any)

  public init?<T>(_ concreteValue: StylePropertyValue<T>?) {
    if let concreteValue = concreteValue {
      self.init(concreteValue)
      return
    }
    return nil
  }

  public init<T>(_ concreteValue: StylePropertyValue<T>) {
    switch concreteValue {
    case .inherit:
      self = .inherit
    case let .value(value):
      self = .value(value)
    }
  }
}
```

compile in release mode crashes when return statement after self.init is not present, but passes when compiling in debug mode