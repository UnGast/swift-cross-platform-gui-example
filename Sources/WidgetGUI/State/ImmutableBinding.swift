import CXShim

@propertyWrapper
public class ImmutableBinding<O>: InternalReactiveProperty {
  public typealias Value = O

  public var value: Value {
    wrappedValue
  }
  public var wrappedValue: Value {
    _get()
  }
  private let _get: () ->Value 

  lazy public private(set) var publisher = PropertyPublisher<Value>(getCurrentValue: { [weak self] in self?.value })

  lazy public var projectedValue = ReactivePropertyProjection<Value>(getImmutable: { [unowned self] in
    return ImmutableBinding(self, get: {
      $0
    })
  }, publisher: AnyPublisher(publisher))

  private var dependencySubscription: AnyCancellable?

  public init<DependencyValue, Dependency: ReactiveProperty>(
    _ dependency: Dependency,
    get _get: @escaping (DependencyValue) -> Value) where Dependency.Value == DependencyValue {
      self._get = { [dependency] in
        _get(dependency.value)
      }

      dependencySubscription = dependency.publisher.sink { [unowned self] _ in
        notifyChange()
      }
  }

  public init(get _get: @escaping () -> Value) {
    self._get = _get
  }
}