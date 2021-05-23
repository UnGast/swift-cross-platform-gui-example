import CXShim

extension Widget {
  @propertyWrapper
  public class State<V>: InternalMutableReactiveProperty {
    public typealias Value = V

    public var value: Value {
      get { wrappedValue }
      set { wrappedValue = newValue }
    }
    public var wrappedValue: Value {
      didSet {
        notifyChange()
      }
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

    public init(wrappedValue: Value) {
      self.wrappedValue = wrappedValue
    }
  }
}