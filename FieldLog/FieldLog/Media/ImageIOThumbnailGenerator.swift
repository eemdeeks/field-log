
//  ImageIOThumbnailGenerator.swift
//  FieldLog

import Foundation
import ImageIO
import CoreGraphics

/// ThumbnailGenerating의 ImageIO 구현체.
/// kCGImageSourceThumbnailMaxPixelSize로 크기를 제한하고 JPEG으로 재인코딩한다.
/// 상태가 없으므로 Swift 6 Sendable 자동 적합.
final class ImageIOThumbnailGenerator: ThumbnailGenerating {

    func thumbnail(from imageData: Data, targetSize: Int) -> Data? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: targetSize,
                  kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary) else { return nil }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, "public.jpeg" as CFString, 1, nil
        ) else { return nil }

        CGImageDestinationAddImage(destination, cgImage, [
            kCGImageDestinationLossyCompressionQuality: 0.7
        ] as CFDictionary)

        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
