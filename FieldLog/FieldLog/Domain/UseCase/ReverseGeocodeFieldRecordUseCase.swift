
//  ReverseGeocodeFieldRecordUseCase.swift
//  FieldLog

import Foundation

/// 건당 1개 레코드의 좌표를 한글 주소로 변환해 영속화한다.
/// CreateFieldRecordUseCase와 같은 패턴 — 변환(역지오코딩) + 영속화를 한 UseCase가 조율.
/// 반복/순차 제어는 호출자(ViewModel)가 담당.
struct ReverseGeocodeFieldRecordUseCase {
    let geocoder: any GeocodingService
    let repository: any FieldRecordRepository

    /// 성공 시 주소를 저장하고 그 주소 문자열을 반환, 실패 시 저장하지 않고 nil (조용히).
    func callAsFunction(id: UUID, coordinate: Coordinate) async -> String? {
        guard let address = try? await geocoder.reverseGeocode(coordinate) else { return nil }
        try? await repository.updateAddress(id: id, address: address)
        return address
    }
}
