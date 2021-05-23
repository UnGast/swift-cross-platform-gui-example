import CXShim

public class ReactivePropertyProjection<V> {
  public typealias Value = V

  private let getImmutable: () -> ImmutableBinding<Value>
  public let publisher: AnyPublisher<Value, Never>

  public var immutable: ImmutableBinding<Value> {
    getImmutable()
  }

  init(getImmutable: @escaping () -> ImmutableBinding<Value>, publisher: AnyPublisher<Value, Never>) {
    self.getImmutable = getImmutable
    self.publisher = publisher
  }
}

public class MutableReactivePropertyProjection<V>: ReactivePropertyProjection<V> {
  private let getMutable: () -> MutableBinding<Value>

  public var mutable: MutableBinding<Value> {
    getMutable()
  }

  init(getImmutable: @escaping () -> ImmutableBinding<Value>, getMutable: @escaping () -> MutableBinding<Value>, publisher: AnyPublisher<Value, Never>) {
    self.getMutable = getMutable
    super.init(getImmutable: getImmutable, publisher: publisher)
  }
}