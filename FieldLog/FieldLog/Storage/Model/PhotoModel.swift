
//  PhotoModel.swift
//  FieldLog

import Foundation
import SwiftData

/// 사진 한 장의 SwiftData 영속 모델.
/// imageData는 externalStorage로 SQLite 외부 파일에 저장.
/// thumbnailData는 지도 표시용 다운샘플 이미지. 수 KB 수준의 작은 데이터라 인라인 저장.
/// exifLatitude/exifLongitude/capturedAt은 EXIF 원본 — FieldRecord.coordinate(확정 위치)와 별개.
@Model
final class PhotoModel {
    @Attribute(.externalStorage) var imageData: Data
    var thumbnailData: Data?
    var exifLatitude: Double?
    var exifLongitude: Double?
    var capturedAt: Date?

    init(imageData: Data, thumbnailData: Data?, exifLatitude: Double?, exifLongitude: Double?, capturedAt: Date?) {
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.exifLatitude = exifLatitude
        self.exifLongitude = exifLongitude
        self.capturedAt = capturedAt
    }
}
