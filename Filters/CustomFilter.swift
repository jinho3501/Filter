import UIKit

struct CustomFilter {
    static func applyFilters(_ image: UIImage, settings: FilterSettings) -> UIImage {
        let bright = applyBrightness(image, value: CGFloat(settings.brightness))
        let contrast = applyContrast(bright, value: CGFloat(settings.contrast))
        let final = applySaturation(contrast, value: CGFloat(settings.saturation))
        return final
    }

    static func applyBrightness(_ image: UIImage, value: CGFloat) -> UIImage {
        return processImage(image) { r, g, b in
            (clamp(r + value), clamp(g + value), clamp(b + value))
        }
    }

    static func applyContrast(_ image: UIImage, value: CGFloat) -> UIImage {
        return processImage(image) { r, g, b in
            ((r - 128) * value + 128, (g - 128) * value + 128, (b - 128) * value + 128)
        }
    }

    static func applySaturation(_ image: UIImage, value: CGFloat) -> UIImage {
        return processImage(image) { r, g, b in
            let avg = (r + g + b) / 3
            let newR = clamp(avg + (r - avg) * value)
            let newG = clamp(avg + (g - avg) * value)
            let newB = clamp(avg + (b - avg) * value)
            return (newR, newG, newB)
        }
    }

    private static func processImage(_ image: UIImage, filter: (CGFloat, CGFloat, CGFloat) -> (CGFloat, CGFloat, CGFloat)) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8

        guard let colorSpace = cgImage.colorSpace,
              let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let buffer = context.data else { return image }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let pixelBuffer = buffer.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let r = CGFloat(pixelBuffer[offset])
                let g = CGFloat(pixelBuffer[offset + 1])
                let b = CGFloat(pixelBuffer[offset + 2])

                let (nr, ng, nb) = filter(r, g, b)
                pixelBuffer[offset]     = UInt8(clamp(nr))
                pixelBuffer[offset + 1] = UInt8(clamp(ng))
                pixelBuffer[offset + 2] = UInt8(clamp(nb))
            }
        }

        guard let outputCG = context.makeImage() else { return image }
        return UIImage(cgImage: outputCG)
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        return min(max(value, 0), 255)
    }
}
