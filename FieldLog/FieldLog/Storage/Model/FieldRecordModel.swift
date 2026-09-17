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
@Model
final class FieldRecordModel {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var latitude: Double
    var longitude: Double
    var memo: String?

    init(id: UUID, timestamp: Date, latitude: Double, longitude: Double, memo: String?) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.memo = memo
    }
}
