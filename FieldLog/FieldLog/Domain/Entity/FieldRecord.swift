//
//  FieldRecord.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation

/// 현장 기록 엔티티. 확정 위치·저장 시각·메모·사진을 담는 순수 값 타입.
/// coordinate: EXIF GPS 또는 추후 사용자가 수동 지정한 확정 위치 (항상 존재).
/// createdAt: 저장 시각 (정렬 키). photo.metadata.capturedAt(EXIF 촬영 시각)과 구분.
struct FieldRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    let coordinate: Coordinate
    let createdAt: Date
    var memo: String?
    let photo: Photo

    /// EXIF GPS가 있는 Photo로부터 자동 생성. coordinate가 없으면 nil.
    /// "EXIF → 레코드 자동 생성" 규칙의 단일 출처.
    init?(autoFrom photo: Photo, createdAt: Date = .now) {
        guard let coordinate = photo.metadata.coordinate else { return nil }
        self.id = UUID()
        self.coordinate = coordinate
        self.createdAt = createdAt
        self.memo = nil
        self.photo = photo
    }

    init(id: UUID, coordinate: Coordinate, createdAt: Date, memo: String?, photo: Photo) {
        self.id = id
        self.coordinate = coordinate
        self.createdAt = createdAt
        self.memo = memo
        self.photo = photo
    }
}
