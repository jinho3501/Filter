import UIKit

extension UIImage {
 
    func fixOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return normalizedImage
    }


    func resized(to maxDimension: CGFloat) -> UIImage {
        let aspectRatio = size.width / size.height
        var newWidth = maxDimension
        var newHeight = maxDimension

        if aspectRatio > 1 {
            newHeight = maxDimension / aspectRatio
        } else {
            newWidth = maxDimension * aspectRatio
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: newWidth, height: newHeight))
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: CGSize(width: newWidth, height: newHeight)))
        }
    }
}
