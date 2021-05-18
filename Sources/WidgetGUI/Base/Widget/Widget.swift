import Foundation
import Drawing
import GfxMath
import VisualAppBase
import ColorizeSwift
import Events
import CXShim

open class Widget: Bounded, Parent, Child, CustomDebugStringConvertible {
    /* identification
    ------------------------------
    */
    public var name: String {
        String(describing: type(of: self))
    }

    public static var nextId: UInt = 2
    public let id: UInt

    // TODO: is this even used?
    open var key: String?

    public var debugDescription: String {
        "\(name) \(id) \(classes) \(treePath)"
    } 
    /* end identification */

    /* tree properties
    ------------------------
    anything that is related to identification, navigation, messaging, etc. in a tree
    */
    open var _context: WidgetContext?
    open var context: WidgetContext {
        // TODO: might cache _context
        get {
            if let context = _context {
                return context
            }

            if let parent = parent as? Widget {
                return parent.context
            }
            
            fatalError("tried to access context when it was not yet available")
        }

        set {
            _context = newValue
        }
    }
    private var contextOnTickHandlerRemover: (() -> ())? = nil

    @usableFromInline
    internal var inspectionBus: WidgetBus<WidgetInspectionMessage> {
        context.inspectionBus
    }
    public internal(set) var lifecycleBus = WidgetBus<WidgetLifecycleMessage>()

    weak open var parent: Parent? = nil {
        didSet {
            onParentChanged.invokeHandlers(parent)
        }
    }
    public internal(set) var treePath: TreePath = [] {
        didSet {
            specificWidgetStyle?.treePath = treePath
        }
    }
    /** The topmost parent or the widget instance itself if not mounted into a parent. */
    public var rootParent: Widget {
        var maxParent = parent as? Widget
        while let nextParent = maxParent?.parent as? Widget {
            maxParent = nextParent
        }
        return maxParent ?? self
    }

    public var children: [Widget] {
        var result = contentChildren
        if scrollingEnabled.x {
            result.append(pseudoScrollBarX)
        }
        if scrollingEnabled.y {
            result.append(pseudoScrollBarY)
        }
        return result
    }
    internal var previousChildren = [Widget]()
    public var contentChildren: [Widget] = [] {
        didSet {
            if mounted && built {
                requestUpdateChildren()
            }
        }
    }

    public var providedDependencies: [Dependency] = []

    /* focus */
    @State internal var internalFocused: Bool = false
    @ImmutableBinding public var focused: Bool
    /* end focus */
    /* end tree properties */

    /* lifecycle
    ---------------------------
    */
    var nextTickHandlerRemovers: [() -> ()] = []
    /* end lifecycle */
    
    /* layout, position
    -----------------------------------------------------
    */
    public var referenceConstraints: BoxConstraints?
    public internal(set) var previousConstraints: BoxConstraints?

    lazy public internal(set) var explicitConstraints = calculateExplicitConstraints()
    var explicitConstraintsUpdateTriggersSubscription: AnyCancellable?
    /// bridge explicitConstraints for use in @inlinable functions
    @usableFromInline internal var _explicitConstraints: BoxConstraints {
        get {
            explicitConstraints
        }

        set {
            explicitConstraints = newValue
        }
    }
    
    open private(set) var layoutedSize = DSize2(0, 0) {
        didSet {
            if oldValue != layoutedSize {
                if mounted {
                    invalidateCumulatedValues()
                    if layouted && !layouting && !destroyed {
                        onSizeChanged.invokeHandlers(layoutedSize)
                    }
                }
            }
        }
    }

    open var layoutedPosition = DPoint2(0, 0) {
        didSet {
            if mounted {
                invalidateCumulatedValues()
            }
        }
    }

    @inlinable open var bounds: DRect {
        DRect(min: layoutedPosition, size: layoutedSize)
    }
    
    @inlinable open var globalBounds: DRect {
        cumulatedTransforms.transform(rect: DRect(min: .zero, size: bounds.size))
    }
    
    @inlinable open var globalPosition: DPoint2 {
        cumulatedTransforms.transform(point: .zero)
    }
    
    public internal(set) var cumulatedTransforms: [DTransform2] = []
    /* end layout, position */
 
    public internal(set) var mounted = false
    public internal(set) var built = false
    // TODO: maybe something better
    public var layoutable: Bool {
        mounted/* && constraints != nil*/ && context != nil
    }
    public var buildInvalid = false
    public private(set) var layouting = false
    public private(set) var layouted = false
    // TODO: maybe rename to boundsInvalid???
    public internal(set) var layoutInvalid = false
    @State private var internalDestroyed = false
    @ImmutableBinding public var destroyed: Bool

    /* style
    -----------------
    */   
    open var classes: [String] = [] {
        didSet {
            notifySelectorChanged()
        }
    }
    public internal(set) var pseudoClasses = Set<String>()

    /** storage for the the value from style getter property */
    internal var specificWidgetStyle: Style? = nil
    /** this style will be added to every widget instance as the last style */ 
    open var style: Style? {
        nil
    } 

    /** whether this Widget creates a new scope for the children which it itself instantiates */
    public var createsStyleScope: Bool = false {
        didSet {
            if mounted {
                fatalError("tried to set createsStyleScope at the wrong time, can only set it during init")
            }
        }
    }
    /** the scope this Widget belongs to */
    public var styleScope: UInt = 0
    public static let rootStyleScope: UInt = 1
    internal static var activeStyleScope: UInt = rootStyleScope

    /** Styles which can be applied to this Widget instance or any of 
    it's children (deep) according to their selector. */
    public var providedStyles: [Style] = []
    var mergedProvidedStyles: [Style] {
        if specificWidgetStyle == nil {
            specificWidgetStyle = style
            specificWidgetStyle?.treePath = treePath
        }
        return providedStyles + (specificWidgetStyle == nil ? [] : [specificWidgetStyle!])
    }

    internal var matchedStylesInvalid = false
    internal var matchedStyles: [Style] = [] {
        didSet {
            if oldValue.count != matchedStyles.count || !oldValue.allSatisfy({ old in matchedStyles.contains { $0 === old } }) {
                invalidateResolvedStyleProperties()
            }
        }
    }
    public internal(set) var DirectStylePropertyValueDefinitions: [StylePropertyValueDefinition] = [] {
        didSet {
            invalidateResolvedStyleProperties()
        }
    }

    @DefaultStyleProperty
    public var width: Double? = nil

    @DefaultStyleProperty
    public var height: Double? = nil

    @DefaultStyleProperty
    public var minWidth: Double? = nil

    @DefaultStyleProperty
    public var minHeight: Double? = nil

    @DefaultStyleProperty
    public var maxWidth: Double? = nil

    @DefaultStyleProperty
    public var maxHeight: Double? = nil

    @DefaultStyleProperty
    public var padding: Insets = .zero
    
    @DefaultStyleProperty
    public var transform: [DTransform2] = []

    @DefaultStyleProperty
    public var overflowX: Overflow = .show

    @DefaultStyleProperty
    public var overflowY: Overflow = .show

    @DefaultStyleProperty
    public var opacity: Double = 1

    @DefaultStyleProperty
    public var visibility: Visibility = .visible

    @DefaultStyleProperty
    public var borderWidth: BorderWidth = .zero

    @DefaultStyleProperty
    public var borderColor: Color = .transparent

    @DefaultStyleProperty
    public var background: Color = .transparent

    @DefaultStyleProperty(default: .inherit)
    public var foreground: Color = .black

    // text, font
    @DefaultStyleProperty(default: .inherit)
    public var fontSize: Double = 16

    @DefaultStyleProperty(default: .inherit)
    public var fontFamily: FontFamily = defaultFontFamily

    @DefaultStyleProperty(default: .inherit)
    public var fontWeight: FontWeight = .regular

    @DefaultStyleProperty(default: .inherit)
    public var fontStyle: FontStyle = .normal

    @DefaultStyleProperty(default: .inherit)
    public var textTransform: TextTransform = .none
    // end text, font

    // flex
    @DefaultStyleProperty
    public var grow: Double = 0

    @DefaultStyleProperty
    public var shrink: Double = 0

    @DefaultStyleProperty
    public var alignSelf: SimpleLinearLayout.Align? = nil

    @DefaultStyleProperty
    public var margin: Insets = Insets(all: 0)
    // end flex
    /* end style */

    /* scrolling
    ------------------------------------
    */
    /*@MutableProperty
    internal var autoScrollingEnabled = (x: false, y: false)*/
    var scrollingEnabled: (x: Bool, y: Bool) = (false, false) {
        didSet {
            if oldValue != scrollingEnabled {
                updateScrollEventHandlers()
            }
        }
    }
    var scrollingEnabledUpdateSubscription: AnyCancellable?
    /** removers for event handlers that are registered to manage scrolling */
    private var scrollingSpeed = 20.0
    @State
    internal var currentScrollOffset: DVec2 = .zero
    internal var scrollableLength: DVec2 = .zero
    /** Mainly used to avoid scroll bars being translated with the rest of the content. */
    internal var unaffectedByParentScroll = false

    lazy internal var pseudoScrollBarX = ScrollBar(orientation: .horizontal)
    lazy internal var pseudoScrollBarY = ScrollBar(orientation: .vertical)

    var scrollSubscriptions = [AnyCancellable]()
    var scrollMouseWheelHandlerRemover: (() -> ())?
    /* end scrolling */

    @usableFromInline internal var reference: AnyReferenceProtocol? {
        didSet {
            if var reference = reference {
                reference.anyReferenced = self
            }
        }
    }

    @State
    public var debugLayout: Bool = false

    public internal(set) var onParentChanged = EventHandlerManager<Parent?>()
    public let onDependenciesInjected = WidgetEventHandlerManager<Void>()
    public internal(set) var onMounted = EventHandlerManager<Void>()
    public let onBuilt = WidgetEventHandlerManager<Void>()
    public let onBuildInvalidated = WidgetEventHandlerManager<Void>()
    public internal(set) var onTick = WidgetEventHandlerManager<Tick>()
    public internal(set) var onSizeChanged = EventHandlerManager<DSize2>()
    public internal(set) var onLayoutInvalidated = EventHandlerManager<Void>()
    public internal(set) var onLayoutingStarted = EventHandlerManager<BoxConstraints>()
    public internal(set) var onLayoutingFinished = EventHandlerManager<DSize2>()
    public internal(set) var onRenderStateInvalidated = EventHandlerManager<Widget>()
    public internal(set) var onDestroy = EventHandlerManager<Void>()

    /* input events
    --------------------------
    */
    public let onMouseEnterHandlerManager = EventHandlerManager<GUIMouseEnterEvent>()
    public let onMouseMoveHandlerManager = EventHandlerManager<GUIMouseMoveEvent>()
    public let onMouseLeaveHandlerManager = EventHandlerManager<GUIMouseLeaveEvent>()
    public let onClickHandlerManager = EventHandlerManager<GUIMouseButtonClickEvent>()
    public let onMouseDownHandlerManager = EventHandlerManager<GUIMouseButtonDownEvent>()
    public let onMouseUpHandlerManager = EventHandlerManager<GUIMouseButtonUpEvent>()
    public let onMouseWheelHandlerManager = EventHandlerManager<GUIMouseWheelEvent>()

    public let onKeyDownHandlerManager = EventHandlerManager<GUIKeyDownEvent>()
    public let onKeyUpHandlerManager = EventHandlerManager<GUIKeyUpEvent>()

    public let onTextInputHandlerManager = EventHandlerManager<GUITextInputEvent>()
    /* end input events */

    public var cancellables = Set<AnyCancellable>()
    
    public init() {
        self.id = Self.nextId
        Self.nextId += 1
        self.styleScope = Widget.activeStyleScope

        self._focused = ImmutableBinding(get: { false })        
        self._destroyed = ImmutableBinding(get: { false })

        self._focused = self.$internalFocused.immutable
        self._destroyed = self.$internalDestroyed.immutable

        setupWidgetEventHandlerManagers()
        setupStyleProperties()
        setupExplicitConstraintsUpdateTriggers()
        setupScrollingEnabled()
        updateScrollEventHandlers() 
    }
    
    /* internal widget setup / management
    -----------------------------------------------------
    */
    private func setupWidgetEventHandlerManagers() {
        let mirror = Mirror(reflecting: self)
        for child in mirror.allChildren {
            if var manager = child.value as? AnyWidgetEventHandlerManager {
                manager.widget = self
            }
        }
    }

    private func setupExplicitConstraintsUpdateTriggers() {
        explicitConstraintsUpdateTriggersSubscription = Publishers.MergeMany([
            $width.publisher, $height.publisher, $minWidth.publisher, $minHeight.publisher, $maxWidth.publisher, $maxHeight.publisher
        ]).sink { [unowned self] _ in
            updateExplicitConstraints()
        }
    }

    private func setupScrollingEnabled() {
        scrollingEnabledUpdateSubscription = Publishers.MergeMany([
            $overflowX.publisher, $overflowY.publisher
        ]).sink { [unowned self] _ in
            scrollingEnabled = (overflowX == .scroll, overflowY == .scroll)
        }
    }

    private func updateScrollEventHandlers() {
        scrollSubscriptions = []
        scrollMouseWheelHandlerRemover?()

        if scrollingEnabled.x || scrollingEnabled.y {
            $currentScrollOffset.publisher.removeDuplicates().sink { [unowned self] in
                let updatedXProgress = $0.x / layoutedSize.width
                if !updatedXProgress.isNaN && updatedXProgress != pseudoScrollBarX.scrollProgress {
                    pseudoScrollBarX.scrollProgress = updatedXProgress
                }

                let updatedYProgress = $0.y / layoutedSize.height
                if !updatedYProgress.isNaN && updatedYProgress != pseudoScrollBarY.scrollProgress {
                    pseudoScrollBarY.scrollProgress = updatedYProgress
                }
            }.store(in: &scrollSubscriptions)

            pseudoScrollBarX.$scrollProgress.publisher.removeDuplicates().sink { [unowned self] in
                let updated = $0 * layoutedSize.width
                if updated != currentScrollOffset.x {
                    currentScrollOffset.x = updated
                }
            }.store(in: &scrollSubscriptions)

            pseudoScrollBarY.$scrollProgress.publisher.removeDuplicates().sink { [unowned self] in
                let updated = $0 * layoutedSize.height
                if updated != currentScrollOffset.y {
                    currentScrollOffset.y = updated
                }
            }.store(in: &scrollSubscriptions)

            scrollMouseWheelHandlerRemover = onMouseWheelHandlerManager.addHandler { [unowned self] event in
                processMouseWheelEventUpdateScroll(event)
            }
        }
    }

    /** Used if the widget is in scrolling mode. Updates the scroll position based on mouse wheel events. */
    private func processMouseWheelEventUpdateScroll(_ event: GUIMouseWheelEvent) {
        let enabledDimensions = DVec2(scrollingEnabled.x ? 1 : 0, scrollingEnabled.y ? 1 : 0)
        self.currentScrollOffset -= event.scrollAmount * self.scrollingSpeed * enabledDimensions
        self.currentScrollOffset = max(.zero, min(self.currentScrollOffset, self.scrollableLength))
    }
    /* end internal widget setup / management */

    // TODO: maybe find better names for the following functions?
    @inlinable
    public final func with(key: String) -> Self {
        self.key = key
        return self
    }

    @inlinable
    public final func connect(ref reference: AnyReferenceProtocol) -> Self {
        self.reference = reference
        self.reference!.anyReferenced = self
        return self
    }

    @inlinable
    public final func with(block: (Self) -> ()) -> Self {
        block(self)
        return self
    }

    final func setupContext() {
        contextOnTickHandlerRemover = context.onTick({ [weak self] in
          if let self = self {
            self.onTick.invokeHandlers($0)
          } else {
            print("THERE IS NO SELF IN ON TICK!")
          }
        })
    }
    
    private final func undoContextSetup() {
      if contextOnTickHandlerRemover == nil {
        print("warn: called undoContextSetup when remove handler is nil")
      }
      if let remove = contextOnTickHandlerRemover {
        remove()
      }
    }

    open func performBuild() {
        
    }

    /** Use if children are added after the initial mount, build phase. Executes immediately.
    // TODO: consider whether executing this in root tick handling would be better
    */   
    public final func requestUpdateChildren() {
        context.queueLifecycleMethodInvocation(.updateChildren, target: self, sender: self, reason: .undefined)
    }

    @inlinable
    public final func invalidateBuild() {
        if buildInvalid {
            #if DEBUG
            Logger.warn("Called invalidateBuild() on a Widget where build is already invalid: \(self)", context: .WidgetBuilding)
            #endif
            return
        }

        if !mounted || destroyed {
            #if DEBUG
            Logger.warn("Called invalidateBuild() on a Widget that has not yet been mounted or is already destroyed: \(self)", context: .WidgetBuilding)
            #endif
            return
        }

        _invalidateBuild()
    }

    @usableFromInline
    @inlinable
    internal final func _invalidateBuild() {
        buildInvalid = true

        context.queueLifecycleMethodInvocation(.build, target: self, sender: self, reason: .undefined)
        
        onBuildInvalidated.invokeHandlers()
    }

    internal func updateExplicitConstraints() {
        // TODO: implement inspection messages
        let currentExplicitConstraints = explicitConstraints
        let newExplicitConstraints = calculateExplicitConstraints()
        if currentExplicitConstraints != newExplicitConstraints {
            _explicitConstraints = newExplicitConstraints
            // TODO: test whether to really invalidate layout?
            invalidateLayout()
        }
    }

    internal func calculateExplicitConstraints() -> BoxConstraints {
        var explicitConstraints = BoxConstraints(minSize: .zero, maxSize: .infinity)

        let paddingSize = padding.aggregateSize
        explicitConstraints.minSize += paddingSize
        explicitConstraints.maxSize += paddingSize
        let borderSize = borderWidth.aggregateSize
        explicitConstraints.minSize += borderSize
        explicitConstraints.maxSize += borderSize

        if overflowX == .scroll {
            explicitConstraints.minSize.width = 0
        }
        if overflowY == .scroll {
            explicitConstraints.minSize.height = 0
        }

        if let explicitMinWidth = minWidth {
            explicitConstraints.minSize.width = explicitMinWidth
            explicitConstraints.maxSize.width = max(explicitConstraints.minSize.width, explicitConstraints.maxSize.width)
        }
        if let explicitMinHeight = minHeight {
            explicitConstraints.minSize.height = explicitMinHeight
            explicitConstraints.maxSize.height = max(explicitConstraints.minSize.height, explicitConstraints.maxSize.height)
        }

        if let explicitMaxWidth = maxWidth {
            explicitConstraints.maxSize.width = explicitMaxWidth 
            explicitConstraints.minSize.width = min(explicitConstraints.minSize.width, explicitConstraints.maxSize.width)
        }
        if let explicitMaxHeight = maxHeight {
            explicitConstraints.maxSize.height = explicitMaxHeight 
            explicitConstraints.minSize.height = min(explicitConstraints.minSize.height, explicitConstraints.maxSize.height)
        }

        if let explicitWidth = width {
            explicitConstraints.minSize.width = explicitWidth
            explicitConstraints.maxSize.width = explicitWidth
        }
        if let explicitHeight = height {
            explicitConstraints.minSize.height = explicitHeight
            explicitConstraints.maxSize.height = explicitHeight
        }

        return explicitConstraints
    }

    public final func layout(constraints: BoxConstraints) {
        if !layoutInvalid, let previousConstraints = previousConstraints, constraints == previousConstraints {
            #if DEBUG
            Logger.log("Constraints equal pervious constraints and layout is not invalid.", "Not performing layout.".with(fg: .yellow), level: .Message, context: .WidgetLayouting)
            #endif
            return
        }
        
        if !layoutable {
            #if DEBUG
            Logger.warn("Called layout() on Widget that is not layoutable: \(self)", context: .WidgetLayouting)
            #endif
            return
        }

        if layouting {
            #if DEBUG
            Logger.warn("Called layout() on Widget while that Widget was still layouting: \(self)", context: .WidgetLayouting)
            #endif
            return
        }

        _layout(constraints: constraints)
    }

    @usableFromInline
    internal final func _layout(constraints: BoxConstraints) {
        if constraints.minWidth.isInfinite || constraints.minHeight.isInfinite {
            fatalError("Widget received constraints that contain infinite value in min size: \(self)")
        }

        //print("LAYOUT", self, "WITH CONSTRAINTS", constraints)

        layouting = true

        onLayoutingStarted.invokeHandlers(constraints)

        for child in children {
            child.layoutedPosition = .zero
        }

        let previousSize = layoutedSize
        let isFirstRound = !layouted
        
        let explicitConstraintsConstraints = BoxConstraints(minSize: explicitConstraints.minSize, maxSize: explicitConstraints.maxSize)
        let constrainedParentConstraints = BoxConstraints(
            minSize: explicitConstraintsConstraints.constrain(constraints.minSize),
            maxSize: explicitConstraintsConstraints.constrain(constraints.maxSize)
        )
        var contentConstraints: BoxConstraints = constrainedParentConstraints - padding.aggregateSize - borderWidth.aggregateSize
        if overflowX == .scroll {
            contentConstraints.maxSize.x = .infinity
        }
        if overflowY == .scroll {
            contentConstraints.maxSize.y = .infinity
        }
        
        let newUnconstrainedContentSize = performLayout(constraints: contentConstraints)

        let targetSize = newUnconstrainedContentSize + padding.aggregateSize + borderWidth.aggregateSize
        
        // warning: this description is possibly outdated
        // final size constraints are used to determine the size of a scroll container
        // the perform layout outputs the size of the whole content
        // -> the content can have any size, because it can be scrolled,
        // therefore it is ok to just apply the max constraints passed in by the parent
        // to the whole widget -> content whill be scrollable if it overflows
        /*var finalSizeConstraints = explicitConstraintsConstraints
        if overflowX == .scroll {
            finalSizeConstraints.maxSize.width = explicitConstraintsConstraints.constrain(constraints.maxSize).width
        }
        if overflowY == .scroll {
            finalSizeConstraints.maxSize.height = explicitConstraintsConstraints.constrain(constraints.maxSize).height
        }*/
        let finalSizeConstraints = BoxConstraints(
            minSize: explicitConstraintsConstraints.constrain(constraints.minSize),
            maxSize: explicitConstraintsConstraints.constrain(constraints.maxSize)
        )
        layoutedSize = finalSizeConstraints.constrain(targetSize)
        /*print("LAYOUT", self)
        print("size", size)
        print("target size", targetSize)
        print("constraints", constraints)
        print("content constraints", contentConstraints)
        print("box config constraints", explicitConstraintsConstraints)
        print("final size constraints", finalSizeConstraints)
        print("------------")*/
        
        scrollableLength = DVec2(targetSize - layoutedSize)

        // TODO: implement logic for overflow == .auto

        /*var scrollBarsLength = DSize2(width, height)
        if scrollingEnabled.x && scrollingEnabled.y {
            scrollBarsLength -= DSize2(pseudoScrollBarY.size.x, pseudoScrollBarX.size.y)
        }*/

        if scrollingEnabled.x {
            pseudoScrollBarX.maxScrollProgress = scrollableLength.x / layoutedSize.width
            pseudoScrollBarX.layout(constraints: BoxConstraints(
                minSize: DSize2(layoutedSize.width, 0),
                maxSize: DSize2(layoutedSize.width, .infinity)))

            pseudoScrollBarX.layoutedPosition = DVec2(0, layoutedSize.height - pseudoScrollBarX.layoutedSize.height)
        }
        if scrollingEnabled.y {
            pseudoScrollBarY.maxScrollProgress = scrollableLength.y / layoutedSize.height
            pseudoScrollBarY.layout(constraints: BoxConstraints(
                minSize: DSize2(0, layoutedSize.height),
                maxSize: DSize2(.infinity, layoutedSize.height)))

            pseudoScrollBarY.layoutedPosition = DVec2(layoutedSize.width - pseudoScrollBarY.layoutedSize.width, 0)
        }

        layouting = false
        layouted = true
        layoutInvalid = false
        
        // TODO: where to call this? after setting bounds or before?
        onLayoutingFinished.invokeHandlers(bounds.size)

        if previousSize != layoutedSize && !isFirstRound {
            onSizeChanged.invokeHandlers(layoutedSize)
        }

        /*for child in children {
            context.queueLifecycleMethodInvocation(.resolveCumulatedValues, target: child, sender: self, reason: .undefined)
        }*/
        //context.queueLifecycleMethodInvocation(.resolveCumulatedValues, target: self, sender: self, reason: .undefined)

        self.previousConstraints = constraints
    }

    /** Layout the content of a widget. Should be implemented by subclasses.
    - Returns: The size of the layouted content. The returned size may exceed or
    fall short of the given constraints.
    */
    open func performLayout(constraints: BoxConstraints) -> DSize2 {
        fatalError("performLayout(constraints:) not implemented.")
    }

    @inlinable
    public final func invalidateLayout() {
        if !mounted {
            //print("warning: called invalidateLayout() on a widget that is not yet mounted")
            return
        }

        if layoutInvalid {
            #if DEBUG
            Logger.warn("Called invalidateLayout() on a Widget where layout is already invalid: \(self)", context: .WidgetLayouting)
            #endif
            return
        }

        _invalidateLayout()
    }

    @usableFromInline
    internal final func _invalidateLayout() {
        layoutInvalid = true
        context.queueLifecycleMethodInvocation(.layout, target: self, sender: self, reason: .undefined)
        onLayoutInvalidated.invokeHandlers(Void())
    }

    @inlinable
    @available(*, deprecated, message: "do not use render object api")
    public final func invalidateRenderState(deep: Bool = false) {

    }

    @inlinable
    @available(*, deprecated, message: "do not use render object api")
    public final func invalidateRenderState(deep: Bool = false, after block: () -> ()) {
    }

    /**
    Run something on the next tick.
    */
    public func nextTick(_ block: @escaping (Tick) -> ()) {
        let remove = context.onTick.once(block)
        nextTickHandlerRemovers.append(remove)
    }
    
    // TODO: how to name this?
    public final func destroy() {
        cancellables = []

        for child in children {
            child.destroy()
        }
        
        mounted = false
        
        undoContextSetup()
        
        if var reference = reference {
            if reference.anyReferenced === self {
                reference.anyReferenced = nil
            }
        }

        // TODO: maybe automatically clear all EventHandlerManagers / WidgetEventHandlerManagers by using reflection?
        

        for remove in nextTickHandlerRemovers {
            remove()
        }

        parent = nil

        destroySelf()
        
        onDestroy.invokeHandlers(Void())

        onParentChanged.removeAllHandlers()
        onMounted.removeAllHandlers()
        onSizeChanged.removeAllHandlers()
        onLayoutInvalidated.removeAllHandlers()
        onLayoutingStarted.removeAllHandlers()
        onLayoutingFinished.removeAllHandlers()
        onRenderStateInvalidated.removeAllHandlers()
        onDestroy.removeAllHandlers()

        let mirror = Mirror(reflecting: self)
        for child in mirror.allChildren {
            if var manager = child.value as? AnyWidgetEventHandlerManager {
                manager.removeAllHandlers()
                manager.widget = nil
            } else if var manager = child.value as? AnyEventHandlerManager {
                manager.removeAllHandlers()
            }/* else if var property = child.value as? AnyReactiveProperty {
                property.destroy()
            }*/
        } 

        internalDestroyed = true

        Logger.log("Destroyed Widget: \(self), \(id)", level: .Message, context: .Default)
    }

    open func destroySelf() {}

    deinit {
      if !destroyed {
        fatalError("Deinitialized Widget without calling destroy() first")
      }
      Logger.log("Deinitialized Widget: \(id) \(self)", level: .Message, context: .Default)
    }
}