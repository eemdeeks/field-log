//
//  FieldRecordMapper.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation

/// Domain Entity ↔ SwiftData 모델 간 양방향 변환.
extension FieldRecordModel {
    func toDomain() -> FieldRecord {
        FieldRecord(
            id: id,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            memo: memo
        )
    }
}

extension FieldRecord {
    func toModel() -> FieldRecordModel {
        FieldRecordModel(
            id: id,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            memo: memo
        )
    }
}
