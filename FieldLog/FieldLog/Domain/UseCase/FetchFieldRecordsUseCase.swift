//
//  FetchFieldRecordsUseCase.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation

/// 현장 기록 전체 조회.
/// mutation 후 ViewModel이 이 UseCase를 재호출해 리프레시한다 (ModelContext 알림 스트리밍 미사용).
struct FetchFieldRecordsUseCase {
    let repository: any FieldRecordRepository

    func callAsFunction() async throws -> [FieldRecord] {
        try await repository.fetchAll()
    }
}
