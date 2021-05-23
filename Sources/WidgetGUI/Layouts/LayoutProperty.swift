import CXShim

@propertyWrapper
public class LayoutProperty<T>: AnyLayoutProperty {
  private var keyPath: KeyPath<Container, AnySpecialStyleProperty<Container, T>>
  unowned var layoutInstance: Layout? {
    didSet {
      setupInstancePropertySubscription()
    }
  }
  var instancePropertySubscription: AnyCancellable?

  public var wrappedValue: T {
    layoutInstance!.container[keyPath: keyPath].resolvedValue
  }

  public init(_ keyPath: KeyPath<Container, AnySpecialStyleProperty<Container, T>>) {
    self.keyPath = keyPath
  }

  func setupInstancePropertySubscription() {
    instancePropertySubscription = layoutInstance!.container[keyPath: keyPath].publisher.sink { [unowned self] _ in
      layoutInstance!.container.invalidateLayout()
    }
  }
}

internal protocol AnyLayoutProperty: class {
  var layoutInstance: Layout? { get set }
}