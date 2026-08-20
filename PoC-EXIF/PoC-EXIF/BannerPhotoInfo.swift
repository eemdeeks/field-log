//
//  BannerPhotoInfo.swift
//  PoC-EXIF
//
//  Created by 박승찬 on 8/20/26.
//


import PhotosUI
import ImageIO
import CoreLocation
import SwiftUI

struct BannerPhotoInfo {
    let image: UIImage
    let location: CLLocation?
    let creationDate: Date?
}

enum PhotoLoadError: Error {
    case dataLoadFailed
    case imageDecodeFailed
}

@MainActor
final class BannerPhotoLoader: ObservableObject {

    @Published var photoInfos: [BannerPhotoInfo] = []

    /// EXIF DateTimeOriginal 포맷: "yyyy:MM:dd HH:mm:ss"
    private let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC") // 필요시 조정
        return formatter
    }()

    func loadPhotos(from items: [PhotosPickerItem]) async {
        var results: [BannerPhotoInfo] = []

        for item in items {
            do {
                let info = try await loadPhotoInfo(from: item)
                results.append(info)
                print(info)
            } catch {
                print("사진 로드 실패: \(error)")
            }
        }

        self.photoInfos = results

    }

    private func loadPhotoInfo(from item: PhotosPickerItem) async throws -> BannerPhotoInfo {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw PhotoLoadError.dataLoadFailed
        }

        guard let uiImage = UIImage(data: data) else {
            throw PhotoLoadError.imageDecodeFailed
        }

        let (location, creationDate) = extractEXIF(from: data)

        return BannerPhotoInfo(
            image: uiImage,
            location: location,
            creationDate: creationDate
        )
    }

    // MARK: - EXIF 파싱

    private func extractEXIF(from data: Data) -> (location: CLLocation?, creationDate: Date?) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return (nil, nil)
        }

        let location = extractLocation(from: properties)
        let creationDate = extractCreationDate(from: properties)

        return (location, creationDate)
    }

    private func extractLocation(from properties: [CFString: Any]) -> CLLocation? {
        guard let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] else {
            return nil
        }

        guard var latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
              var longitude = gps[kCGImagePropertyGPSLongitude] as? Double
        else {
            return nil
        }

        // GPS Ref(N/S/E/W)에 따라 부호 반영
        if let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String, latRef == "S" {
            latitude = -latitude
        }
        if let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String, lonRef == "W" {
            longitude = -longitude
        }

        guard CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) else {
            return nil
        }

        return CLLocation(latitude: latitude, longitude: longitude)
    }

    private func extractCreationDate(from properties: [CFString: Any]) -> Date? {
        // Exif > DateTimeOriginal 우선, 없으면 DateTimeDigitized로 폴백
        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            if let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String,
               let date = exifDateFormatter.date(from: dateString) {
                return date
            }
            if let dateString = exif[kCGImagePropertyExifDateTimeDigitized] as? String,
               let date = exifDateFormatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
}
