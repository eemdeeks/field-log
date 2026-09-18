//
//  CreateFieldRecordUseCase.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation

/// 현장 기록 생성.
/// 향후 위치 유효성 검사, 사진 첨부 조합 등 앱 로직의 중심이 될 UseCase.
struct CreateFieldRecordUseCase {
    let repository: any FieldRecordRepository

    func callAsFunction(_ record: FieldRecord) async throws {
        try await repository.create(record)
    }
}
