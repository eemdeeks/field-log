
//  Photo.swift
//  FieldLog

import Foundation

/// 사진 한 장. 이미지 바이트와 EXIF 메타데이터를 함께 보관.
/// metadata.coordinate는 EXIF 원본(optional) — 저장 시 FieldRecord.coordinate(확정 위치)와 구분된다.
/// id는 SwiftUI ForEach identity용. Equatable은 imageData + metadata 기준(id, thumbnailData 제외).
/// thumbnailData는 imageData의 다운샘플 파생물이므로 동등성 비교에서 제외한다.
struct Photo: Identifiable, Equatable, Sendable {
    let id: UUID
    let imageData: Data
    let thumbnailData: Data?
    let metadata: PhotoMetadata

    init(imageData: Data, metadata: PhotoMetadata, thumbnailData: Data? = nil) {
        self.id = UUID()
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.metadata = metadata
    }

    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.imageData == rhs.imageData && lhs.metadata == rhs.metadata
    }
}
