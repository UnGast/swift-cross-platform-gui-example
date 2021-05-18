import GfxMath
import CXShim
import Drawing

public class Container: ContentfulWidget, SlotAcceptingWidgetProtocol {
  public static let defaultSlot = Slot(key: "default", data: Void.self)
  var defaultSlotManager = SlotContentManager(Container.defaultSlot)
  public var defaultNoDataSlotContentManager: SlotContentManager<Void>? {
    defaultSlotManager
  }

  override public var content: DirectContent {
    defaultSlotManager()
  }

  override public var contentChildren: [Widget] {
    didSet {
      updateLayoutInstance()
    }
  }

  private var layoutInstance: Layout?

  @StyleProperty
  public var layout: Layout.Type = SimpleLinearLayout.self
  var layoutChangeSubscription: AnyCancellable?

  @StyleProperty
  public var direction: SimpleLinearLayout.Direction = .row

  @StyleProperty
  public var alignContent: SimpleLinearLayout.Align = .start

  @StyleProperty
  public var justifyContent: SimpleLinearLayout.Justify = .start

  override public init() {
      super.init()

      /*_ = stylePropertiesResolver.onResolvedPropertyValuesChanged { [unowned self] in
        let oldLayoutType = $0.old[StyleKeys.layout.asString] as? Layout.Type
        let newLayoutType = $0.new[StyleKeys.layout.asString] as? Layout.Type

        if (oldLayoutType != nil && newLayoutType != nil && ObjectIdentifier(oldLayoutType!) != ObjectIdentifier(newLayoutType!)) ||
          (oldLayoutType == nil && newLayoutType != nil) || (oldLayoutType != nil && newLayoutType == nil) {
            updateLayoutInstance()
        } else {
          updateLayoutInstanceProperties()
        }
      }*/
      layoutChangeSubscription = $layout.publisher.map(ObjectIdentifier.init).removeDuplicates().sink { [unowned self] _ in
        updateLayoutInstance()
      }

      //_ = onDestroy(removeChildrenLayoutPropertiesHandlers)

      updateLayoutInstance()
  }

  private func updateLayoutInstance() {
    //removeChildrenLayoutPropertiesHandlers()

    layoutInstance = layout.init(container: self, widgets: contentChildren)
    //stylePropertiesResolver.propertySupportDefinitions = mergedSupportedStyleProperties
    //stylePropertiesResolver.resolve()

    /*if layoutInstance!.childPropertySupportDefinitions.count > 0 {
      for child in contentChildren {
        child.supportedParentStyleProperties["layout"] = layoutInstance!.childPropertySupportDefinitions
        child.stylePropertiesResolver.propertySupportDefinitions = child.mergedSupportedStyleProperties
        child.stylePropertiesResolver.resolve()

        childrenLayoutPropertiesHandlerRemovers.append(child.stylePropertiesResolver.onResolvedPropertyValuesChanged { [unowned self] _ in
          invalidateLayout()
        })
      }
    }*/
  }

  /*private func updateLayoutInstanceProperties() {
    for property in layoutInstance!.parentPropertySupportDefinitions {
      layoutInstance!.layoutPropertyValues[property.key.asString] = stylePropertyValue(property.key)
    }
    if mounted && layouted {
      invalidateLayout()
    }
  }*/

  /*private func removeChildrenLayoutPropertiesHandlers() {
    for remove in childrenLayoutPropertiesHandlerRemovers {
      remove()
    }
    childrenLayoutPropertiesHandlerRemovers = []
  }*/

  override public func performLayout(constraints: BoxConstraints) -> DSize2 {
    let accumulatedSize = layoutInstance!.layout(constraints: constraints)
    return accumulatedSize
  }
}