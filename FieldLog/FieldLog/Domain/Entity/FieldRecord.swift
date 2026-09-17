//
//  FieldRecord.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation

/// 현장 기록 엔티티. 위치·시간·메모를 담는 순수 값 타입.
/// imageData는 사진 기능 구현 시 VersionedSchema 마이그레이션으로 추가 예정.
struct FieldRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    var memo: String?
}
