
//  AddRecordViewModelTests.swift
//  FieldLogTests

import Foundation
import Testing
@testable import FieldLog

// MARK: - Helpers

/// GPS가 있는 Photo 생성 헬퍼.
private func makePhoto(hasGPS: Bool) -> Photo {
    let coordinate: Coordinate? = hasGPS ? Coordinate(latitude: 37.5, longitude: 127.0) : nil
    return Photo(
        imageData: Data([0xFF, 0xD8]),
        metadata: PhotoMetadata(coordinate: coordinate, capturedAt: Date(timeIntervalSince1970: 1_000_000))
    )
}

// MARK: - Tests

@Suite("AddRecordViewModel - save")
@MainActor
struct AddRecordViewModelTests {

    private func makeSUT() -> (vm: AddRecordViewModel, fake: FakeFieldRecordLocalDataSource) {
        let fake = FakeFieldRecordLocalDataSource()
        let repository = FieldRecordRepositoryImpl(local: fake)
        let vm = AddRecordViewModel(
            extractMetadata: ExtractPhotoMetadataUseCase(extractor: StubExtractor()),
            createRecord: CreateFieldRecordUseCase(repository: repository),
            fetchRecords: FetchFieldRecordsUseCase(repository: repository)
        )
        return (vm, fake)
    }

    @Test("GPS 있는 사진만 저장되고 GPS 없는 사진은 제외된다")
    func savesOnlyPhotosWithGPS() async throws {
        let (vm, fake) = makeSUT()
        vm.extracted = [makePhoto(hasGPS: true), makePhoto(hasGPS: false), makePhoto(hasGPS: true)]

        await vm.save()

        #expect(fake.records.count == 2)
    }

    @Test("imageData가 저장된 레코드에 포함된다")
    func imageDataIsPreserved() async throws {
        let (vm, fake) = makeSUT()
        let photo = makePhoto(hasGPS: true)
        vm.extracted = [photo]

        await vm.save()

        #expect(fake.records.first?.photo.imageData == photo.imageData)
    }

    @Test("저장 후 extracted와 pickerItems가 초기화된다")
    func clearsStateAfterSave() async throws {
        let (vm, _) = makeSUT()
        vm.extracted = [makePhoto(hasGPS: true)]

        await vm.save()

        #expect(vm.extracted.isEmpty)
        #expect(vm.pickerItems.isEmpty)
    }

    @Test("autoLocatableCount는 GPS 있는 사진 수만 반환한다")
    func autoLocatableCountOnlyCountsGPS() {
        let (vm, _) = makeSUT()
        vm.extracted = [makePhoto(hasGPS: true), makePhoto(hasGPS: false)]

        #expect(vm.autoLocatableCount == 1)
    }

    @Test("FieldRecord(autoFrom:)는 GPS 없는 Photo에 대해 nil을 반환한다")
    func autoFromReturnsNilWithoutGPS() {
        let photo = makePhoto(hasGPS: false)
        #expect(FieldRecord(autoFrom: photo) == nil)
    }
}

// MARK: - Stub Extractor (ExtractPhotoMetadataUseCase 초기화용, save 테스트에서 미사용)

private final class StubExtractor: PhotoMetadataExtracting, @unchecked Sendable {
    func extract(from imageData: Data) async throws -> PhotoMetadata {
        PhotoMetadata(coordinate: nil, capturedAt: nil)
    }
}
