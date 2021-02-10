import VisualAppBase

extension Widget {
  public class LifecycleMethodInvocationQueue {
    var entries: [Entry] = []

    public init() {}

    public func queue(_ entry: Entry) {
      entries.append(entry)
    }

    public func clear() {
      entries = []
    }

    public func iterateSubTreeRoots() -> Iterator {
      // TODO: implement iterator in such a way that when a new item is added to the queue
      // this item is inserted into the iterator at the correct position -> if at a higher level
      // than currently at, add it as the item for the next iteration (items already iterated are discarded by the iterator)
      // and remove the items below it
      // if it is not included in a tree path already in the iterator, add it to the end
      Iterator(entries: entries)
    }

    public class Entry {
      public var method: LifecycleMethod
      public var target: Widget
      public var sender: Widget
      public var reason: LifecycleMethodInvocationReason
      public var tick: Tick

      public init(method: LifecycleMethod, target: Widget, sender: Widget, reason: LifecycleMethodInvocationReason, tick: Tick) {
        self.method = method
        self.target = target
        self.sender = sender
        self.reason = reason
        self.tick = tick
      }
    }

    public class Iterator: IteratorProtocol {
      var entries: [Entry]

      public init(entries: [Entry]) {
        self.entries = entries
      }

      public func next() -> Entry? {
        entries.popLast()
      }
    }
  }
}