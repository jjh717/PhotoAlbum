//
//  UIImage+Resize.swift
//  PhotoAlbum
//
//  Created by jjh717
//

import UIKit
import CoreGraphics
import ImageIO
import Accelerate

extension UIImage {

    // MARK: - Resize Framework

    enum ResizeFramework {
        case uikit, coreImage, coreGraphics, imageIO, accelerate
    }

    // MARK: - Public API

    /// Resize image maintaining aspect ratio to fit within the given dimension.
    /// - Parameters:
    ///   - dimension: Maximum width or height.
    ///   - resizeFramework: Framework to use for resizing.
    /// - Returns: Resized image, or self if already within bounds.
    func resizeWithScaleAspectFitMode(
        to dimension: CGFloat,
        resizeFramework: ResizeFramework = .coreGraphics
    ) -> UIImage? {
        guard max(size.width, size.height) > dimension else { return self }

        let aspectRatio = size.width / size.height
        let newSize: CGSize
        if aspectRatio > 1 {
            newSize = CGSize(width: dimension, height: dimension / aspectRatio)
        } else {
            newSize = CGSize(width: dimension * aspectRatio, height: dimension)
        }
        return resize(to: newSize, with: resizeFramework)
    }

    /// Resize image to the given size.
    func resize(to newSize: CGSize, with framework: ResizeFramework = .coreGraphics) -> UIImage? {
        switch framework {
        case .uikit:        return resizeWithUIKit(to: newSize)
        case .coreImage:    return resizeWithCoreImage(to: newSize)
        case .coreGraphics: return resizeWithCoreGraphics(to: newSize)
        case .imageIO:      return resizeWithImageIO(to: newSize)
        case .accelerate:   return resizeWithAccelerate(to: newSize)
        }
    }

    // MARK: - File Size Info

    func fileSizeString(
        compressionQuality: CGFloat = 0.9,
        allowedUnits: ByteCountFormatter.Units = .useMB
    ) -> String? {
        guard let data = jpegData(compressionQuality: compressionQuality) else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = allowedUnits
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(data.count))
    }

    // MARK: - UIKit (Modern)

    private func resizeWithUIKit(to newSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Core Image

    private func resizeWithCoreImage(to newSize: CGSize) -> UIImage? {
        guard let cgImage,
              let filter = CIFilter(name: "CILanczosScaleTransform") else { return nil }

        let ciImage = CIImage(cgImage: cgImage)
        let scale = newSize.width / ciImage.extent.size.width

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value: Double(scale)), forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey: kCIInputAspectRatioKey)

        guard let outputImage = filter.outputImage else { return nil }
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let resultCGImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        return UIImage(cgImage: resultCGImage)
    }

    // MARK: - Core Graphics

    private func resizeWithCoreGraphics(to newSize: CGSize) -> UIImage? {
        guard let cgImage, let colorSpace = cgImage.colorSpace else { return nil }

        guard let context = CGContext(
            data: nil,
            width: Int(newSize.width),
            height: Int(newSize.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0, // Let CG calculate optimal row bytes
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else { return nil }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: newSize))
        return context.makeImage().map { UIImage(cgImage: $0) }
    }

    // MARK: - ImageIO

    private func resizeWithImageIO(to newSize: CGSize) -> UIImage? {
        guard let data = jpegData(compressionQuality: 1.0),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: max(newSize.width, newSize.height),
        ]

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: thumbnail)
    }

    // MARK: - Accelerate

    private func resizeWithAccelerate(to newSize: CGSize) -> UIImage? {
        guard let cgImage else { return nil }

        guard var sourceBuffer = try? vImage_Buffer(cgImage: cgImage),
              var destBuffer = try? vImage_Buffer(
                  width: Int(newSize.width),
                  height: Int(newSize.height),
                  bitsPerPixel: UInt32(cgImage.bitsPerPixel)
              ) else { return nil }

        defer {
            sourceBuffer.free()
            destBuffer.free()
        }

        let error = vImageScale_ARGB8888(&sourceBuffer, &destBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
        guard error == kvImageNoError else { return nil }

        guard let format = vImage_CGImageFormat(cgImage: cgImage),
              let resultImage = try? destBuffer.createCGImage(format: format) else { return nil }

        return UIImage(cgImage: resultImage)
    }
}
