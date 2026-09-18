//
//  FieldRecordUseCaseTests.swift
//  FieldLogTests
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation
import Testing
@testable import FieldLog

// MARK: - Fake Repository

/// 배열 기반 가짜 Repository. UseCase가 올바른 메서드로 위임하는지만 검증한다.
final class FakeFieldRecordRepository: FieldRecordRepository, @unchecked Sendable {
    var records: [FieldRecord] = []
    var createCallCount = 0
    var fetchCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0

    func create(_ record: FieldRecord) async throws {
        createCallCount += 1
        records.append(record)
    }

    func fetchAll() async throws -> [FieldRecord] {
        fetchCallCount += 1
        return records
    }

    func update(_ record: FieldRecord) async throws {
        updateCallCount += 1
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        }
    }

    func delete(id: UUID) async throws {
        deleteCallCount += 1
        records.removeAll { $0.id == id }
    }
}

// MARK: - Tests

@Suite("CreateFieldRecordUseCase")
struct CreateFieldRecordUseCaseTests {
    @Test("create 호출 시 repository.create로 위임한다")
    func delegatesToRepository() async throws {
        let repo = FakeFieldRecordRepository()
        let useCase = CreateFieldRecordUseCase(repository: repo)
        let record = FieldRecord(id: UUID(), timestamp: .now, latitude: 37.5, longitude: 127.0, memo: nil)

        try await useCase(record)

        #expect(repo.createCallCount == 1)
        #expect(repo.records.first?.id == record.id)
    }
}

@Suite("FetchFieldRecordsUseCase")
struct FetchFieldRecordsUseCaseTests {
    @Test("fetch 호출 시 repository.fetchAll로 위임하고 결과를 반환한다")
    func delegatesToRepository() async throws {
        let repo = FakeFieldRecordRepository()
        let record = FieldRecord(id: UUID(), timestamp: .now, latitude: 37.5, longitude: 127.0, memo: "test")
        repo.records = [record]
        let useCase = FetchFieldRecordsUseCase(repository: repo)

        let result = try await useCase()

        #expect(repo.fetchCallCount == 1)
        #expect(result.count == 1)
        #expect(result.first?.id == record.id)
    }
}

@Suite("UpdateFieldRecordUseCase")
@MainActor
struct UpdateFieldRecordUseCaseTests {
    @Test("update 호출 시 repository.update로 위임한다")
    func delegatesToRepository() async throws {
        let repo = FakeFieldRecordRepository()
        let original = FieldRecord(id: UUID(), timestamp: .now, latitude: 37.5, longitude: 127.0, memo: nil)
        repo.records = [original]
        let updated = FieldRecord(id: original.id, timestamp: original.timestamp, latitude: original.latitude, longitude: original.longitude, memo: "updated")
        let useCase = UpdateFieldRecordUseCase(repository: repo)

        try await useCase(updated)

        #expect(repo.updateCallCount == 1)
        #expect(repo.records.first?.memo == "updated")
    }
}

@Suite("DeleteFieldRecordUseCase")
struct DeleteFieldRecordUseCaseTests {
    @Test("delete 호출 시 repository.delete로 위임한다")
    func delegatesToRepository() async throws {
        let repo = FakeFieldRecordRepository()
        let record = FieldRecord(id: UUID(), timestamp: .now, latitude: 37.5, longitude: 127.0, memo: nil)
        repo.records = [record]
        let useCase = DeleteFieldRecordUseCase(repository: repo)

        try await useCase(id: record.id)

        #expect(repo.deleteCallCount == 1)
        #expect(repo.records.isEmpty)
    }
}
