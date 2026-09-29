
//  Photo.swift
//  FieldLog

import Foundation

/// 사진 한 장. 이미지 바이트와 EXIF 메타데이터를 함께 보관.
/// metadata.coordinate는 EXIF 원본(optional) — 저장 시 FieldRecord.coordinate(확정 위치)와 구분된다.
/// id는 SwiftUI ForEach identity용. Equatable은 imageData + metadata 기준(id 제외).
struct Photo: Identifiable, Equatable, Sendable {
    let id: UUID
    let imageData: Data
    let metadata: PhotoMetadata

    init(imageData: Data, metadata: PhotoMetadata) {
        self.id = UUID()
        self.imageData = imageData
        self.metadata = metadata
    }

    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.imageData == rhs.imageData && lhs.metadata == rhs.metadata
    }
}
