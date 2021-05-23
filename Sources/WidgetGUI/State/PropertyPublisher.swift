import CXShim

public class PropertyPublisher<O>: Publisher {
  public typealias Output = O
  public typealias Failure = Never

  private var getCurrentValue: () -> O?
  private var subscriptions: [WeakBox<ReactivePropertySubscription<O>>] = []

  public init(getCurrentValue: @escaping () -> O?) {
    self.getCurrentValue = getCurrentValue
  }

  public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
    let subscription = ReactivePropertySubscription<Output>(subscriber: AnySubscriber(subscriber))
    subscriptions.append(WeakBox(subscription))
    subscriber.receive(subscription: subscription)
    if let currentValue = getCurrentValue() {
      subscription.receive(currentValue)
    } else {
      print("warning: no current value present when registering subscriber on property publisher")
    }
  }

  internal func emit(_ value: Output) {
    for subscription in subscriptions {
      if let subscription = subscription.wrapped {
        subscription.receive(value)
      }
    }
  }
}

internal class ReactivePropertySubscription<V>: Subscription {
  private var subscriber: AnySubscriber<V, Never>?

  init(subscriber: AnySubscriber<V, Never>) {
    self.subscriber = subscriber
  }

  func request(_ demand: Subscribers.Demand) {}

  func receive(_ value: V) {
    _ = subscriber?.receive(value)
  }

  func cancel() {
    subscriber = nil
  }
}