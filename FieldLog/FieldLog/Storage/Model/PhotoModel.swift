
//  PhotoModel.swift
//  FieldLog

import Foundation
import SwiftData

/// 사진 한 장의 SwiftData 영속 모델.
/// imageData는 externalStorage로 SQLite 외부 파일에 저장.
/// exifLatitude/exifLongitude/capturedAt은 EXIF 원본 — FieldRecord.coordinate(확정 위치)와 별개.
@Model
final class PhotoModel {
    @Attribute(.externalStorage) var imageData: Data
    var exifLatitude: Double?
    var exifLongitude: Double?
    var capturedAt: Date?

    init(imageData: Data, exifLatitude: Double?, exifLongitude: Double?, capturedAt: Date?) {
        self.imageData = imageData
        self.exifLatitude = exifLatitude
        self.exifLongitude = exifLongitude
        self.capturedAt = capturedAt
    }
}
