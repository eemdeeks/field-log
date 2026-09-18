//
//  FieldRecordRepositoryImpl.swift
//  FieldLog
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation

/// FieldRecordRepository 구현체. Persistence/Network DataSource를 조합하는 조율자.
/// SwiftData를 직접 알지 않는다 — FieldRecordLocalDataSource에만 의존한다.
@MainActor
final class FieldRecordRepositoryImpl: FieldRecordRepository {
    private let local: any FieldRecordLocalDataSource

    init(local: any FieldRecordLocalDataSource) {
        self.local = local
    }

    func create(_ record: FieldRecord) async throws {
        try local.create(record)
    }

    func fetchAll() async throws -> [FieldRecord] {
        try local.fetchAll()
    }

    func update(_ record: FieldRecord) async throws {
        try local.update(record)
    }

    func delete(id: UUID) async throws {
        try local.delete(id: id)
    }
}
