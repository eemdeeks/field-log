
//  CLGeocoderService.swift
//  FieldLog

import CoreLocation
import Foundation

/// GeocodingService의 CLGeocoder 구현체. iOS 17–25 fallback.
/// iOS 26+에서는 MKGeocoderService로 교체된다.
/// preferredLocale: ko_KR — 한글 주소 반환.
final class CLGeocoderService: GeocodingService {

    func reverseGeocode(_ coordinate: Coordinate) async throws -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try await CLGeocoder().reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "ko_KR"))
        guard let placemark = placemarks.first else {
            throw GeocodingError.noResult
        }
        let address = buildAddress(from: placemark)
        guard !address.isEmpty else {
            throw GeocodingError.noResult
        }
        return address
    }

    // MARK: - Private

    /// administrativeArea → locality → subLocality → thoroughfare → subThoroughfare 순으로
    /// 공백 join. nil·빈 문자열 제외. 직전 값과 중복이면 스킵.
    private func buildAddress(from placemark: CLPlacemark) -> String {
        let components: [String?] = [
            placemark.administrativeArea,
            placemark.locality,
            placemark.subLocality,
            placemark.thoroughfare,
            placemark.subThoroughfare
        ]
        var result: [String] = []
        for component in components {
            guard let value = component, !value.isEmpty else { continue }
            if result.last != value {
                result.append(value)
            }
        }
        return result.joined(separator: " ")
    }
}
