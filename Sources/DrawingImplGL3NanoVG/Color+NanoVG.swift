import Cnanovg
import GfxMath

public extension Color {
    func toNVG() -> NVGcolor {
        return nvgRGBA(r, g, b, a)
    }
}
