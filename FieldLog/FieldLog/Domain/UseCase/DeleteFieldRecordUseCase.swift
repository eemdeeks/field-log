//
//  DeleteFieldRecordUseCase.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation

/// 현장 기록 삭제.
struct DeleteFieldRecordUseCase {
    let repository: any FieldRecordRepository

    func callAsFunction(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
