//
//  FieldRecordModel.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation
import SwiftData

/// SwiftData 영속 모델.
/// Domain의 FieldRecord와 분리되어 스키마 변경이 Domain에 새지 않는다.
/// latitude/longitude: FieldRecord.coordinate(확정 위치).
/// photo: 사진 데이터와 EXIF 원본을 담은 PhotoModel — cascade 삭제.
@Model
final class FieldRecordModel {
    @Attribute(.unique) var id: UUID
    var latitude: Double
    var longitude: Double
    var createdAt: Date
    var memo: String?
    @Relationship(deleteRule: .cascade) var photo: PhotoModel

    init(id: UUID, latitude: Double, longitude: Double, createdAt: Date, memo: String?, photo: PhotoModel) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.memo = memo
        self.photo = photo
    }
}
