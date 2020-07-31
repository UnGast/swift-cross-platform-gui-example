/*
import Foundation
import CustomGraphicsMath
import VisualAppBase

open class Divider<S: System<W, R>, W: Window, R: Renderer>: Widget<S, W, R> {
    public var color: Color
    public var axis: Axis
    public var width: Double

    public init(color: Color, axis: Axis, width: Double = 1) {
        self.color = color
        self.axis = axis
        self.width = width
        super.init()
    }

    override open func layout() {
        switch axis {
        case .Horizontal:
            bounds.size = DSize2(constraints!.maxWidth, width)
        case .Vertical:
            bounds.size = DSize2(width, constraints!.maxHeight)
        }
    }

    override open func render(renderer: R) throws {
        //print("RENDERME")
        try renderer.rect(globalBounds, style: RenderStyle(fillColor: color))
    }
}
*/