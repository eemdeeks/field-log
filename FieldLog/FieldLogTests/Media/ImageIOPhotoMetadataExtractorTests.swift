
//  ImageIOPhotoMetadataExtractorTests.swift
//  FieldLogTests

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import FieldLog

// MARK: - Helpers

/// 1×1 픽셀 JPEG Data를 생성한다. GPS/EXIF 메타데이터를 선택적으로 포함.
private func makeJPEGData(
    gpsLat: Double? = nil, gpsLatRef: String? = nil,
    gpsLon: Double? = nil, gpsLonRef: String? = nil,
    dateTimeOriginal: String? = nil
) -> Data {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
        data: nil, width: 1, height: 1,
        bitsPerComponent: 8, bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    let cgImage = context.makeImage()!

    var properties: [CFString: Any] = [:]
    if let lat = gpsLat, let latRef = gpsLatRef, let lon = gpsLon, let lonRef = gpsLonRef {
        properties[kCGImagePropertyGPSDictionary] = [
            kCGImagePropertyGPSLatitude: lat,
            kCGImagePropertyGPSLatitudeRef: latRef,
            kCGImagePropertyGPSLongitude: lon,
            kCGImagePropertyGPSLongitudeRef: lonRef
        ] as [CFString: Any]
    }
    if let date = dateTimeOriginal {
        properties[kCGImagePropertyExifDictionary] = [
            kCGImagePropertyExifDateTimeOriginal: date
        ] as [CFString: Any]
    }

    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
    CGImageDestinationFinalize(destination)
    return data as Data
}

// MARK: - Tests

@Suite("ImageIOPhotoMetadataExtractor")
struct ImageIOPhotoMetadataExtractorTests {
    let extractor = ImageIOPhotoMetadataExtractor()

    @Test("GPS와 촬영시각이 있는 사진: 좌표와 capturedAt을 파싱한다")
    func extractsGPSAndDate() async throws {
        let data = makeJPEGData(
            gpsLat: 37.5665, gpsLatRef: "N",
            gpsLon: 126.9780, gpsLonRef: "E",
            dateTimeOriginal: "2026:09:22 10:00:00"
        )

        let result = try await extractor.extract(from: data)

        let coord = try #require(result.coordinate)
        #expect(abs(coord.latitude - 37.5665) < 0.00001)
        #expect(abs(coord.longitude - 126.9780) < 0.00001)
        #expect(result.capturedAt != nil)
    }

    @Test("남위·서경 사진: 좌표 부호가 음수로 변환된다")
    func extractsNegativeCoordinate() async throws {
        let data = makeJPEGData(
            gpsLat: 33.8688, gpsLatRef: "S",
            gpsLon: 151.2093, gpsLonRef: "W"
        )

        let result = try await extractor.extract(from: data)

        let coord = try #require(result.coordinate)
        #expect(coord.latitude < 0)
        #expect(coord.longitude < 0)
    }

    @Test("GPS 없는 사진: coordinate가 nil이다")
    func noGPSReturnsNilCoordinate() async throws {
        let data = makeJPEGData(dateTimeOriginal: "2026:09:22 10:00:00")

        let result = try await extractor.extract(from: data)

        #expect(result.coordinate == nil)
    }

    @Test("GPS 좌표가 0,0인 사진: coordinate가 nil이다")
    func zeroCoordinateReturnsNil() async throws {
        let data = makeJPEGData(
            gpsLat: 0.0, gpsLatRef: "N",
            gpsLon: 0.0, gpsLonRef: "E"
        )

        let result = try await extractor.extract(from: data)

        #expect(result.coordinate == nil)
    }

    @Test("읽을 수 없는 Data: PhotoMetadataError.unreadableImage를 던진다")
    func unreadableDataThrows() async {
        await #expect(throws: PhotoMetadataError.unreadableImage) {
            try await extractor.extract(from: Data([0x00, 0x01, 0x02]))
        }
    }
}
