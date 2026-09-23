
//  Photo.swift
//  FieldLog

import Foundation

/// 사진 한 장. 이미지 바이트와 EXIF 메타데이터를 함께 보관.
/// metadata.coordinate는 EXIF 원본(optional) — 저장 시 FieldRecord.coordinate(확정 위치)와 구분된다.
struct Photo: Equatable, Sendable {
    let imageData: Data
    let metadata: PhotoMetadata
}
