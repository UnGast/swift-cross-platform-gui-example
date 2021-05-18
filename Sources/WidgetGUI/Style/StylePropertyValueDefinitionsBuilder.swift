import CXShim

@_functionBuilder
public struct StylePropertyValueDefinitionsBuilder<W: Widget> {
  public static func buildExpression<V>(_ expression: (KeyPath<Widget, DefaultStyleProperty<V>>, StylePropertyValue<V>)) -> [StylePropertyValueDefinition] {
    [StylePropertyValueDefinition(
      keyPath: expression.0,
      value: .constant(AnyStylePropertyValue(expression.1))
    )]
  }

  public static func buildExpression<V>(_ expression: (KeyPath<W, AnySpecialStyleProperty<W, V>>, StylePropertyValue<V>)) -> [StylePropertyValueDefinition] {
    [StylePropertyValueDefinition(
      keyPath: expression.0,
      value: .constant(AnyStylePropertyValue(expression.1))
    )]
  }

  public static func buildExpression<V>(_ expression: (KeyPath<Widget, DefaultStyleProperty<V>>, V)) -> [StylePropertyValueDefinition] {
    [StylePropertyValueDefinition(
      keyPath: expression.0,
      value: .constant(.value(expression.1))
    )]
  }

  public static func buildExpression<V>(_ expression: (KeyPath<W, AnySpecialStyleProperty<W, V>>, V)) -> [StylePropertyValueDefinition] {
    [StylePropertyValueDefinition(
      keyPath: expression.0,
      value: .constant(.value(expression.1))
    )]
  }

  public static func buildExpression<V, P: ReactiveProperty>(_ expression: (KeyPath<Widget, DefaultStyleProperty<V>>, P)) -> [StylePropertyValueDefinition] where P.Value == V {
    [StylePropertyValueDefinition(
      keyPath: expression.0,
      value: .reactive(expression.1.publisher.map { AnyStylePropertyValue.value($0) }.eraseToAnyPublisher())
    )]
  }

  public static func buildExpression<V, P: ReactiveProperty>(_ expression: (KeyPath<W, AnySpecialStyleProperty<W, V>>, P)) -> [StylePropertyValueDefinition] where P.Value == V {
    [StylePropertyValueDefinition(
      keyPath: expression.0,
      value: .reactive(expression.1.publisher.map { AnyStylePropertyValue.value($0) }.eraseToAnyPublisher())
    )]
  }

  public static func buildBlock(_ partials: [[StylePropertyValueDefinition]]) -> [StylePropertyValueDefinition] {
    partials.flatMap { $0 }
  }

  public static func buildBlock(_ partials: [StylePropertyValueDefinition]...) -> [StylePropertyValueDefinition] {
    buildBlock(partials)
  }
}