//
//  FieldRecordUseCaseTests.swift
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

// MARK: - Fake ThumbnailGenerator

/// 고정 Data를 반환하는 가짜 ThumbnailGenerator.
final class FakeThumbnailGenerator: ThumbnailGenerating {
    let returnValue: Data?
    var callCount = 0

    init(returnValue: Data? = Data([0x01])) {
        self.returnValue = returnValue
    }

    func thumbnail(from imageData: Data, targetSize: Int) -> Data? {
        callCount += 1
        return returnValue
    }
}

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
        let useCase = CreateFieldRecordUseCase(repository: repo, thumbnailGenerator: FakeThumbnailGenerator())
        let record = FieldRecord.make()

        try await useCase(record)

        #expect(repo.createCallCount == 1)
        #expect(repo.records.first?.id == record.id)
    }

    @Test("저장된 레코드의 photo에 썸네일이 첨부된다")
    func thumbnailIsAttachedToSavedRecord() async throws {
        let expectedThumb = Data([0xAB, 0xCD])
        let repo = FakeFieldRecordRepository()
        let useCase = CreateFieldRecordUseCase(
            repository: repo,
            thumbnailGenerator: FakeThumbnailGenerator(returnValue: expectedThumb)
        )
        let record = FieldRecord.make()

        try await useCase(record)

        #expect(repo.records.first?.photo.thumbnailData == expectedThumb)
    }

    @Test("썸네일 생성 실패(nil)에도 저장은 성공한다")
    func saveSuceedsWhenThumbnailIsNil() async throws {
        let repo = FakeFieldRecordRepository()
        let useCase = CreateFieldRecordUseCase(
            repository: repo,
            thumbnailGenerator: FakeThumbnailGenerator(returnValue: nil)
        )

        try await useCase(FieldRecord.make())

        #expect(repo.createCallCount == 1)
        #expect(repo.records.first?.photo.thumbnailData == nil)
    }
}

@Suite("FetchFieldRecordsUseCase")
struct FetchFieldRecordsUseCaseTests {
    @Test("fetch 호출 시 repository.fetchAll로 위임하고 결과를 반환한다")
    func delegatesToRepository() async throws {
        let repo = FakeFieldRecordRepository()
        let record = FieldRecord.make(memo: "test")
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
        let original = FieldRecord.make()
        repo.records = [original]
        let updated = FieldRecord(id: original.id, coordinate: original.coordinate, createdAt: original.createdAt, memo: "updated", photo: original.photo)
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
        let record = FieldRecord.make()
        repo.records = [record]
        let useCase = DeleteFieldRecordUseCase(repository: repo)

        try await useCase(id: record.id)

        #expect(repo.deleteCallCount == 1)
        #expect(repo.records.isEmpty)
    }
}
