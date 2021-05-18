import Foundation
import VisualAppBase
import GfxMath
import CXShim
import Drawing

fileprivate var itemSlots = [ObjectIdentifier: AnySlot]()

public class List<Item: Equatable>: ContentfulWidget, SlotAcceptingWidgetProtocol {
  @ImmutableBinding
  private var items: [Item]
  private var previousItems: [Item] = []

  public static var itemSlot: Slot<Item> {
    if itemSlots[ObjectIdentifier(Item.self)] == nil {
      itemSlots[ObjectIdentifier(Item.self)] = Slot(key: "default", data: Item.self)
    }
    return itemSlots[ObjectIdentifier(Item.self)]! as! Slot<Item>
  }
  var itemSlotManager = SlotContentManager(List.itemSlot)

  var storedContent = DirectContent(partials: [])
  override public var content: DirectContent {
    storedContent
  }
  private var itemContents: [DirectContent] = [] {
    didSet {
      storedContent.partials = itemContents.map {
        .content($0)
      }
    }
  }

  private var itemsSubscription: AnyCancellable?

  public init(items immutableItems: ImmutableBinding<[Item]>) {
    self._items = immutableItems
  }

  override public func performBuild() {
    itemsSubscription = _items.publisher.sink { [unowned self] in
      processItemUpdate(old: previousItems, new: $0)
      previousItems = $0
    }
    super.performBuild()
  }

  private func processItemUpdate(old: [Item], new: [Item]) {
    var updatedItemContents = [DirectContent]()

    var usedOldIndices = [Int]()

    outer: for newItem in new {
      var foundOldIndex: Int?

      for (oldIndex, oldItem) in old.enumerated() {
        if oldItem == newItem, !usedOldIndices.contains(oldIndex), itemContents.count > oldIndex {
          foundOldIndex = oldIndex
          break
        }
      }

      if let oldIndex = foundOldIndex {
        updatedItemContents.append(itemContents[oldIndex])
        usedOldIndices.append(oldIndex)
      } else {
        updatedItemContents.append(itemSlotManager(newItem))
      }
    }

    itemContents = updatedItemContents 
  }

  override public func performLayout(constraints: BoxConstraints) -> DSize2 {
    var currentPosition = DPoint2.zero
    var maxWidth = 0.0

    for child in children {
      let childConstraints = BoxConstraints(minSize: DSize2(constraints.minWidth, 0), maxSize: DSize2(constraints.maxWidth, .infinity))
      // do this comparison to reduce exponential growth of duration
      if childConstraints != child.previousConstraints {
        //print("LIST CURR AND PREV", childConstraints, child.previousConstraints)
        child.layout(constraints: childConstraints)
      }

      child.layoutedPosition = currentPosition

      currentPosition.y += child.layoutedSize.height
      if child.layoutedSize.width > maxWidth {
        maxWidth = child.layoutedSize.width
      }
    }

    return DSize2(maxWidth, currentPosition.y)
  }
}