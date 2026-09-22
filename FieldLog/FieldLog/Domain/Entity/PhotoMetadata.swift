
//  PhotoMetadata.swift
//  FieldLog

import Foundation

/// 사진 한 장에서 추출한 메타데이터. 저장 엔티티가 아니라 추출 결과 값.
/// GPS 없는 사진은 coordinate == nil, EXIF 시각 없는 사진은 capturedAt == nil.
struct PhotoCoordinate: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}

struct PhotoMetadata: Equatable, Sendable {
    let coordinate: PhotoCoordinate?
    let capturedAt: Date?
}
