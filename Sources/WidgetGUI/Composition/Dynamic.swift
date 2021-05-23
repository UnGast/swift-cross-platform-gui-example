import Events
import CXShim

public class Dynamic<C: ContentProtocol> {
  var associatedStyleScope: UInt

  let content: C

  var triggerProperty: AnyObject?
  var triggerSubscription: AnyCancellable?

  private init<P: Publisher>(trigger: P, build: @escaping () -> [C.Partial]) where P.Failure == Never {
    self.associatedStyleScope = Widget.activeStyleScope

    let partials = build()
    self.content = C(partials: partials)
    
    triggerSubscription = trigger.sink { [unowned self] _ in
      Widget.inStyleScope(self.associatedStyleScope) {
        self.content.partials = build()
      }
    }
  }
}

extension Dynamic where C == DirectContent {
  public convenience init<P: Publisher>(_ trigger: P, @DirectContentBuilder build: @escaping () -> [C.Partial]) where P.Failure == Never {
    self.init(trigger: trigger, build: build)
  }
}

extension Dynamic where C == SlottingContent {
  public convenience init<P: Publisher>(_ trigger: P, @SlottingContentBuilder build: @escaping () -> [C.Partial]) where P.Failure == Never {
    self.init(trigger: trigger, build: build)
  }

  public convenience init<P: ReactiveProperty>(_ trigger: P, @SlottingContentBuilder build: @escaping () -> [C.Partial]) {
    self.init(trigger: trigger.publisher, build: build)
    triggerProperty = trigger
  }
}