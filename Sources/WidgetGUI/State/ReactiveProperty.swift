import CXShim

public protocol ReactiveProperty: AnyObject {
  associatedtype Value

  var value: Value { get }

  var publisher: PropertyPublisher<Value> { get }
}

internal protocol ErasedInternalReactiveProperty {
  func notifyChange()
}

internal class AnyErasedInternalReactiveProperty: ErasedInternalReactiveProperty {
  let _notifyChange: () -> ()

  let wrapped: Any

  init<T: ErasedInternalReactiveProperty>(wrapping wrapped: T) {
    self._notifyChange = wrapped.notifyChange
    self.wrapped = wrapped
  }

  func notifyChange() {
    _notifyChange()
  }
}

internal protocol InternalReactiveProperty: ReactiveProperty, ErasedInternalReactiveProperty {
}

extension InternalReactiveProperty {
  internal func notifyChange() {
    publisher.emit(value)
  }
}

public class AnyReactiveProperty<V>: InternalReactiveProperty {
  public typealias Value = V

  public var value: Value {
    didSet {
      notifyChange()
    }
  }

  lazy public private(set) var publisher = PropertyPublisher<Value>(getCurrentValue: { [weak self] in self?.value })
  
  var ownedWrapped: AnyObject

  var wrappedSubscription: AnyObject?

  public init<P: ReactiveProperty>(_ wrapped: P) where P.Value == V {
    self.value = wrapped.value
    self.ownedWrapped = wrapped
    wrappedSubscription = wrapped.publisher.sink(receiveValue: { [unowned self] in
      value = $0
    })
  }
}