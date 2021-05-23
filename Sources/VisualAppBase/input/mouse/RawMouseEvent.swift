//

//

import Foundation
import GfxMath

// TODO: maybe remove the "Raw" again and only prefix GUI for the widget events..
public protocol RawMouseEvent {
    var position: DPoint2 { get set }
}

public struct RawMouseButtonUpEvent: RawMouseEvent {
    public var button: MouseButton
    public var position: DPoint2

    public init(button: MouseButton, position: DPoint2) {
        self.button = button
        self.position = position
    }
}

public struct RawMouseButtonDownEvent: RawMouseEvent {
    public var button: MouseButton
    public var position: DPoint2

    public init(button: MouseButton, position: DPoint2) {
        self.button = button
        self.position = position
    }
}

public struct RawMouseWheelEvent: RawMouseEvent {
    public var scrollAmount: DVec2
    public var position: DPoint2

    public init(scrollAmount: DVec2, position: DPoint2) {
        self.scrollAmount = scrollAmount
        self.position = position
    }
}

public struct RawMouseMoveEvent: RawMouseEvent {
    public var position: DPoint2
    public var previousPosition: DPoint2
    public var move: DVec2 {
        get {
            DVec2(position.x - previousPosition.x, position.y - previousPosition.y)
        }
    }

    public init(position: DPoint2, previousPosition: DPoint2) {
        self.position = position
        self.previousPosition = previousPosition
    }
}