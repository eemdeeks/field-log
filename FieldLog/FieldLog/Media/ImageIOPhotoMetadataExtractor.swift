
//  ImageIOPhotoMetadataExtractor.swift
//  FieldLog

import Foundation
import ImageIO
import CoreGraphics

/// PhotoMetadataExtracting의 ImageIO 구현체.
/// 상태가 없고 nonisolated이므로 오프-메인 스레드에서 안전하게 실행 가능.
final class ImageIOPhotoMetadataExtractor: PhotoMetadataExtracting {

    func extract(from imageData: Data) async throws -> PhotoMetadata {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
            throw PhotoMetadataError.unreadableImage
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]

        return PhotoMetadata(
            coordinate: extractCoordinate(from: properties),
            capturedAt: extractCapturedAt(from: properties)
        )
    }

    private func extractCoordinate(from properties: [CFString: Any]?) -> PhotoCoordinate? {
        guard
            let gps = properties?[kCGImagePropertyGPSDictionary] as? [CFString: Any],
            let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
            let lon = gps[kCGImagePropertyGPSLongitude] as? Double,
            let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
            let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String,
            latRef == "N" || latRef == "S",
            lonRef == "E" || lonRef == "W",
            lat != 0.0 || lon != 0.0
        else { return nil }

        return PhotoCoordinate(
            latitude: latRef == "S" ? -lat : lat,
            longitude: lonRef == "W" ? -lon : lon
        )
    }

    private func extractCapturedAt(from properties: [CFString: Any]?) -> Date? {
        guard
            let exif = properties?[kCGImagePropertyExifDictionary] as? [CFString: Any],
            let raw = exif[kCGImagePropertyExifDateTimeOriginal] as? String
        else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: raw)
    }
}

enum PhotoMetadataError: Error {
    case unreadableImage
}
