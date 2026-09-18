//
//  UpdateFieldRecordUseCase.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation

/// 현장 기록 수정.
/// 위치·시간은 기록 시점 불변으로 간주하며, memo 필드만 변경 대상이다.
struct UpdateFieldRecordUseCase {
    let repository: any FieldRecordRepository

    func callAsFunction(_ record: FieldRecord) async throws {
        try await repository.update(record)
    }
}
