
//  ExtractPhotoMetadataUseCaseTests.swift
//  FieldLogTests

import Foundation
import Testing
@testable import FieldLog

// MARK: - Fake Extractor

/// 고정 PhotoMetadata를 반환하는 가짜 추출기. UseCase가 올바르게 위임·반환하는지만 검증한다.
final class FakePhotoMetadataExtractor: PhotoMetadataExtracting, @unchecked Sendable {
    var extractCallCount = 0
    var stubbedResult: PhotoMetadata = PhotoMetadata(
        coordinate: PhotoCoordinate(latitude: 37.5, longitude: 127.0),
        capturedAt: Date(timeIntervalSince1970: 0)
    )

    func extract(from imageData: Data) async throws -> PhotoMetadata {
        extractCallCount += 1
        return stubbedResult
    }
}

// MARK: - Tests

@Suite("ExtractPhotoMetadataUseCase")
struct ExtractPhotoMetadataUseCaseTests {

    @Test("extractor에 위임하고 결과를 그대로 반환한다")
    func delegatesToExtractor() async throws {
        let fake = FakePhotoMetadataExtractor()
        let useCase = ExtractPhotoMetadataUseCase(extractor: fake)
        let dummyData = Data([0xFF, 0xD8])

        let result = try await useCase(dummyData)

        #expect(fake.extractCallCount == 1)
        #expect(result == fake.stubbedResult)
    }

    @Test("extractor가 throw하면 UseCase도 throw한다")
    func propagatesError() async throws {
        final class ThrowingExtractor: PhotoMetadataExtracting, @unchecked Sendable {
            func extract(from imageData: Data) async throws -> PhotoMetadata {
                throw PhotoMetadataError.unreadableImage
            }
        }
        let useCase = ExtractPhotoMetadataUseCase(extractor: ThrowingExtractor())

        await #expect(throws: PhotoMetadataError.unreadableImage) {
            try await useCase(Data())
        }
    }
}
