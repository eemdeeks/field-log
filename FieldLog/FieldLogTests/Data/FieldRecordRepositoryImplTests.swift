//
//  FieldRecordRepositoryImplTests.swift
//  FieldLogTests
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation
import SwiftData
import Testing
@testable import FieldLog

// MARK: - Helper

/// 매 테스트마다 새 in-memory 컨테이너를 만들어 독립성 보장.
/// ModelContainer는 nonisolated로 생성하고, mainContext·RepositoryImpl만 MainActor.run 안에서 초기화한다.
private func makeInMemoryRepository() async throws -> FieldRecordRepositoryImpl {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: FieldRecordModel.self, configurations: config)
    return await MainActor.run {
        FieldRecordRepositoryImpl(context: container.mainContext)
    }
}

// MARK: - Tests

@Suite("FieldRecordRepositoryImpl")
struct FieldRecordRepositoryImplTests {

    @Test("create 후 fetchAll 시 1건이 저장되고 필드가 일치한다")
    func createAndFetch() async throws {
        let repo = try await makeInMemoryRepository()
        let record = FieldRecord(id: UUID(), timestamp: .now, latitude: 37.5665, longitude: 126.9780, memo: "서울시청")

        try await repo.create(record)
        let fetched = try await repo.fetchAll()

        #expect(fetched.count == 1)
        #expect(fetched[0].id == record.id)
        #expect(fetched[0].latitude == record.latitude)
        #expect(fetched[0].longitude == record.longitude)
        #expect(fetched[0].memo == record.memo)
    }

    @Test("update 후 fetchAll 시 memo가 변경된다")
    func updateMemo() async throws {
        let repo = try await makeInMemoryRepository()
        let id = UUID()
        let timestamp = Date.now
        let original = FieldRecord(id: id, timestamp: timestamp, latitude: 37.5, longitude: 127.0, memo: nil)
        try await repo.create(original)

        let updated = FieldRecord(id: id, timestamp: timestamp, latitude: 37.5, longitude: 127.0, memo: "수정됨")
        try await repo.update(updated)

        let fetched = try await repo.fetchAll()
        #expect(fetched[0].memo == "수정됨")
    }

    @Test("delete 후 fetchAll 시 0건이다")
    func deleteRecord() async throws {
        let repo = try await makeInMemoryRepository()
        let record = FieldRecord(id: UUID(), timestamp: .now, latitude: 37.5, longitude: 127.0, memo: nil)
        try await repo.create(record)

        try await repo.delete(id: record.id)

        let fetched = try await repo.fetchAll()
        #expect(fetched.isEmpty)
    }

    @Test("fetchAll은 timestamp 내림차순으로 반환한다")
    func fetchSortedByTimestampDescending() async throws {
        let repo = try await makeInMemoryRepository()
        let older = FieldRecord(id: UUID(), timestamp: Date(timeIntervalSinceNow: -3600), latitude: 37.0, longitude: 127.0, memo: "older")
        let newer = FieldRecord(id: UUID(), timestamp: Date(timeIntervalSinceNow: 0), latitude: 37.1, longitude: 127.1, memo: "newer")

        try await repo.create(older)
        try await repo.create(newer)

        let fetched = try await repo.fetchAll()
        #expect(fetched.count == 2)
        #expect(fetched[0].memo == "newer")
        #expect(fetched[1].memo == "older")
    }
}
