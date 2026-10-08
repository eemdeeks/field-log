
//  GeocodingService.swift
//  FieldLog

import Foundation

/// 좌표를 주소 문자열로 변환하는 서비스 인터페이스.
/// 저장소(Repository)가 아닌 순수 변환이므로 Service 폴더에 위치.
/// 합성할 DataSource가 둘 이상 생길 여지 없음(CLGeocoder 단일 소스) → 3계층 구조 적용.
/// async: 네트워크 I/O 경계를 열어둠.
protocol GeocodingService: Sendable {
    /// 좌표를 한글 주소 문자열로 변환. 결과 없거나 실패 시 throw.
    func reverseGeocode(_ coordinate: Coordinate) async throws -> String
}
