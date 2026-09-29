
//  Coordinate.swift
//  FieldLog

import Foundation

/// 위도·경도 값 타입. FieldRecord(확정 위치)와 PhotoMetadata(EXIF 원본) 양쪽에서 공용.
struct Coordinate: Equatable, Sendable {
    let latitude: Double
    let longitude: Double
}
