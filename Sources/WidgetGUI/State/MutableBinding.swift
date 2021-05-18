import CXShim

@propertyWrapper
public class MutableBinding<V>: InternalMutableReactiveProperty  {
  public typealias Value = V
  public typealias Output = Value
  public typealias Failure = Never

  public var value: Value {
    get {
      _get()
    }
    set {
      _set(newValue)
    }
  }

  private let _get: () -> Value
  private let _set: (Value) -> ()

  public var wrappedValue: Value {
    get { value }
    set { value = newValue }
  }

  lazy public private(set) var publisher = PropertyPublisher<Value>(getCurrentValue: { [weak self] in self?.value })

  lazy public var projectedValue = MutableReactivePropertyProjection<Value>(getImmutable: { [unowned self] in
    ImmutableBinding(self, get: {
      $0
    })
  }, getMutable: { [unowned self] in
    MutableBinding(self, get: {
      $0
    }, set: {
      $0
    })
  }, publisher: AnyPublisher(publisher))

  private var dependencySubscription: AnyCancellable?

  public init<Dependency: MutableReactiveProperty>(
    _ dependency: Dependency,
    get _get: @escaping (Dependency.Value) -> Value,
    set _set: @escaping (Value) -> Dependency.Value) {
      self._get = { [dependency] in
        _get(dependency.value)
      }
      self._set = { [dependency] in
        dependency.value = _set($0)
      }

      dependencySubscription = dependency.publisher.sink { [unowned self] _ in
        notifyChange()
      }
  }
}