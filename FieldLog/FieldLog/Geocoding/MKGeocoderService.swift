
//  MKGeocoderService.swift
//  FieldLog

import CoreLocation
import MapKit

/// GeocodingService의 MKReverseGeocodingRequest 구현체. iOS 26+.
/// CLGeocoderService(iOS 17–25 fallback)의 deprecated 대체제.
/// composition root에서 #available(iOS 26, *)로 조건부 주입한다.
@available(iOS 26, *)
final class MKGeocoderService: GeocodingService {

    func reverseGeocode(_ coordinate: Coordinate) async throws -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else {
            throw GeocodingError.noResult
        }
        request.preferredLocale = Locale(identifier: "ko_KR")
        let mapItems = try await request.mapItems
        guard let address = mapItems.first?.address else {
            throw GeocodingError.noResult
        }
        let fullAddress = address.fullAddress
        guard !fullAddress.isEmpty else {
            throw GeocodingError.noResult
        }
        return fullAddress
    }
}
