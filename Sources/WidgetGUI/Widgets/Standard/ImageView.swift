import GfxMath
import Foundation
import Events
import Drawing
import Swim

public class ImageView: LeafWidget {
    @ImmutableBinding
    private var image: Swim.Image<RGBA, UInt8>
    private var resizedImage: Swim.Image<RGBA, UInt8>?
    private var imageChanged: Bool = true
    private var drawableImage: Image2?

    private var imageSubscription: Any?
    
    public init(image imageBinding: ImmutableBinding<Swim.Image<RGBA, UInt8>>) {
        self._image = imageBinding
        super.init()
        
        var oldImageSize = (image.width, image.height)
        self.imageSubscription = $image.publisher.sink { [unowned self] newImage in
            let newImageSize = (newImage.width, newImage.height)
            if oldImageSize != newImageSize {
                oldImageSize = newImageSize
                drawableImage = nil
                invalidateLayout()
            }
            imageChanged = true
        }
    }

    override public func performLayout(constraints: BoxConstraints) -> DSize2 {
        var width = max(constraints.minWidth, min(constraints.maxWidth, Double(image.width)))
        var scale = width / Double(image.width)
        var height = Double(image.height) * scale

        if height < constraints.minHeight || height > constraints.maxHeight {
            height = max(constraints.minHeight, min(constraints.maxWidth, Double(image.width)))
            scale = height / Double(image.height)
            width = Double(image.width) * scale
        }

        return constraints.constrain(DSize2(width, height))
    }

    override public func draw(_ drawingContext: DrawingContext) {
        if imageChanged, let drawableImage = self.drawableImage {
            updateResizedImage()
            try! drawableImage.updateData(resizedImage!)
        } else if drawableImage == nil {
            updateResizedImage()
            drawableImage = Image2(fromRGBA: resizedImage!)
        }

        drawingContext.drawImage(image: drawableImage!, topLeft: globalBounds.min)

        imageChanged = false
    }

    private func updateResizedImage() {
        resizedImage = image.resize(width: Int(bounds.size.width), height: Int(bounds.size.height))
    }
}
