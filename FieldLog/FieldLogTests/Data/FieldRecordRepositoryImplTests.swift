//
//  FieldRecordRepositoryImplTests.swift
//  FieldLogTests
//
//  Created by 박승찬 on 9/15/26.
//

import Foundation
import Testing
@testable import FieldLog

// MARK: - Test Helper

private extension FieldRecord {
    static func make(
        id: UUID = UUID(),
        coordinate: Coordinate = Coordinate(latitude: 37.5, longitude: 127.0),
        createdAt: Date = .now,
        memo: String? = nil
    ) -> FieldRecord {
        let photo = Photo(
            imageData: Data([0xFF, 0xD8]),
            metadata: PhotoMetadata(coordinate: coordinate, capturedAt: nil)
        )
        return FieldRecord(id: id, coordinate: coordinate, createdAt: createdAt, memo: memo, photo: photo)
    }
}

// MARK: - Fake DataSource

/// 배열 기반 가짜 DataSource. Repository가 DataSource에 올바르게 위임하는지만 검증한다.
@MainActor
final class FakeFieldRecordLocalDataSource: FieldRecordLocalDataSource {
    var records: [FieldRecord] = []

    func create(_ record: FieldRecord) throws {
        records.append(record)
    }

    func fetchAll() throws -> [FieldRecord] {
        return records
    }

    func update(_ record: FieldRecord) throws {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
    }

    func delete(id: UUID) throws {
        records.removeAll { $0.id == id }
    }
}

// MARK: - Tests

@Suite("FieldRecordRepositoryImpl")
@MainActor
struct FieldRecordRepositoryImplTests {
    let repo: FieldRecordRepositoryImpl

    init() {
        repo = FieldRecordRepositoryImpl(local: FakeFieldRecordLocalDataSource())
    }

    @Test("create 후 fetchAll 시 1건이 저장되고 필드가 일치한다")
    func createAndFetch() async throws {
        let coord = Coordinate(latitude: 37.5665, longitude: 126.9780)
        let record = FieldRecord.make(coordinate: coord, memo: "서울시청")

        try await repo.create(record)
        let fetched = try await repo.fetchAll()

        try #require(fetched.count == 1)
        #expect(fetched[0].id == record.id)
        #expect(fetched[0].coordinate == record.coordinate)
        #expect(fetched[0].memo == record.memo)
    }

    @Test("update 후 fetchAll 시 memo가 변경된다")
    func updateMemo() async throws {
        let id = UUID()
        let createdAt = Date.now
        let original = FieldRecord.make(id: id, createdAt: createdAt)
        try await repo.create(original)

        let updated = FieldRecord(id: id, coordinate: original.coordinate, createdAt: createdAt, memo: "수정됨", photo: original.photo)
        try await repo.update(updated)

        let fetched = try await repo.fetchAll()
        #expect(fetched.first?.memo == "수정됨")
    }

    @Test("delete 후 fetchAll 시 0건이다")
    func deleteRecord() async throws {
        let record = FieldRecord.make()
        try await repo.create(record)

        try await repo.delete(id: record.id)

        let fetched = try await repo.fetchAll()
        #expect(fetched.isEmpty)
    }
}
