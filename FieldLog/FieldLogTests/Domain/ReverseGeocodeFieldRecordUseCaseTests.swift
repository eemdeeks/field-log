
//  ReverseGeocodeFieldRecordUseCaseTests.swift
//  FieldLogTests

import Foundation
import Testing
@testable import FieldLog

// MARK: - Mock GeocodingService

/// 호출 추적과 성공/실패 제어가 가능한 Mock.
/// nonisolated actor를 사용해 실제 병렬 호출 가능성을 열고 순차성을 의미 있게 검증한다.
actor MockGeocodingService: GeocodingService {
    enum Behavior {
        case success(String)
        case failure
    }

    var behavior: Behavior
    var callCount = 0
    var maxConcurrent = 0
    private var activeCount = 0

    init(behavior: Behavior = .success("서울특별시 강남구 테헤란로")) {
        self.behavior = behavior
    }

    nonisolated func reverseGeocode(_ coordinate: Coordinate) async throws -> String {
        await incrementActive()
        // defer로 비동기 Task를 생성하면 decrement가 다음 호출의 increment보다 늦게 실행될 수 있다.
        // await으로 직접 호출해 반환/throw 전에 decrement를 완료한다.
        switch await behavior {
        case .success(let address):
            await decrementActive()
            return address
        case .failure:
            await decrementActive()
            throw GeocodingError.noResult
        }
    }

    private func incrementActive() {
        callCount += 1
        activeCount += 1
        maxConcurrent = max(maxConcurrent, activeCount)
    }

    private func decrementActive() {
        activeCount -= 1
    }
}

// MARK: - Tests

@Suite("ReverseGeocodeFieldRecordUseCase")
struct ReverseGeocodeFieldRecordUseCaseTests {

    @Test("성공 시 주소 문자열을 반환하고 repository.updateAddress를 1회 호출한다")
    func successReturnsAddressAndUpdatesRepository() async {
        let repo = FakeFieldRecordRepository()
        let record = FieldRecord.make()
        repo.records = [record]
        let expectedAddress = "서울특별시 강남구 테헤란로"
        let mock = MockGeocodingService(behavior: .success(expectedAddress))
        let useCase = ReverseGeocodeFieldRecordUseCase(geocoder: mock, repository: repo)

        let result = await useCase(id: record.id, coordinate: record.coordinate)

        #expect(result == expectedAddress)
        #expect(await mock.callCount == 1)
        #expect(repo.updateAddressCallCount == 1)
        #expect(repo.records.first?.address == expectedAddress)
    }

    @Test("실패(throw) 시 nil을 반환하고 repository.updateAddress를 호출하지 않는다")
    func failureReturnsNilWithoutUpdating() async {
        let repo = FakeFieldRecordRepository()
        let record = FieldRecord.make()
        repo.records = [record]
        let mock = MockGeocodingService(behavior: .failure)
        let useCase = ReverseGeocodeFieldRecordUseCase(geocoder: mock, repository: repo)

        let result = await useCase(id: record.id, coordinate: record.coordinate)

        #expect(result == nil)
        #expect(repo.updateAddressCallCount == 0)
        #expect(repo.records.first?.address == nil)
    }

    @Test("실패해도 기존 레코드가 삭제되거나 create가 호출되지 않는다")
    func failureDoesNotAffectOtherRecords() async {
        let repo = FakeFieldRecordRepository()
        let record = FieldRecord.make()
        repo.records = [record]
        let mock = MockGeocodingService(behavior: .failure)
        let useCase = ReverseGeocodeFieldRecordUseCase(geocoder: mock, repository: repo)

        _ = await useCase(id: record.id, coordinate: record.coordinate)

        #expect(repo.records.count == 1)
        #expect(repo.createCallCount == 0)
        #expect(repo.deleteCallCount == 0)
    }
}

// MARK: - AddRecordViewModel 주소 채우기 테스트

@Suite("AddRecordViewModel - 주소 채우기")
@MainActor
struct AddRecordViewModelAddressFillingTests {

    /// Mock geocoder와 addressFillInterval: .zero를 주입해 빠르게 완료하는 SUT.
    private func makeSUT(
        geocodeBehavior: MockGeocodingService.Behavior = .success("서울특별시 강남구 테헤란로")
    ) -> (vm: AddRecordViewModel, geocodeMock: MockGeocodingService, repo: FakeFieldRecordRepositoryForViewModel) {
        let repo = FakeFieldRecordRepositoryForViewModel()
        let geocodeMock = MockGeocodingService(behavior: geocodeBehavior)
        let vm = AddRecordViewModel(
            extractMetadata: ExtractPhotoMetadataUseCase(extractor: StubExtractor()),
            createRecord: CreateFieldRecordUseCase(
                repository: repo,
                thumbnailGenerator: FakeThumbnailGenerator()
            ),
            fetchRecords: FetchFieldRecordsUseCase(repository: repo),
            reverseGeocode: ReverseGeocodeFieldRecordUseCase(
                geocoder: geocodeMock,
                repository: repo
            ),
            addressFillInterval: .zero
        )
        return (vm, geocodeMock, repo)
    }

    @Test("저장 후 주소가 메모리 내 records에 채워진다")
    func addressFilledAfterSave() async throws {
        let (vm, geocodeMock, repo) = makeSUT()
        let photo = makePhotoWithGPS()
        repo.recordsToReturn = [FieldRecord.make(id: UUID())]
        vm.extracted = [photo]

        await vm.save()
        // addressTask 완료 대기
        await vm.addressTask?.value

        #expect(await geocodeMock.callCount >= 1)
        #expect(vm.records.allSatisfy { $0.address != nil })
    }

    @Test("지오코딩 실패 시 address가 nil로 남고 루프가 정상 종료한다")
    func failureKeepsAddressNilAndLoopCompletes() async throws {
        let (vm, geocodeMock, _) = makeSUT(geocodeBehavior: .failure)
        let record = FieldRecord.make()
        vm.records = [record]

        vm.startFillingAddresses()
        await vm.addressTask?.value

        #expect(await geocodeMock.callCount >= 1)
        #expect(vm.records.first?.address == nil)
    }

    @Test("두 번째 save 시 이전 패스에서 실패해 nil로 남은 건을 재스캔한다")
    func rescanNilAddressOnNextSave() async throws {
        let (vm, geocodeMock, repo) = makeSUT()

        // 1차 패스: 실패
        await geocodeMock.setBehavior(.failure)
        let record = FieldRecord.make()
        repo.recordsToReturn = [record]
        vm.extracted = [makePhotoWithGPS()]
        await vm.save()
        await vm.addressTask?.value
        #expect(vm.records.first?.address == nil)

        // 2차 패스: 성공
        await geocodeMock.setBehavior(.success("서울특별시 강남구 테헤란로"))
        vm.extracted = [makePhotoWithGPS()]
        await vm.save()
        await vm.addressTask?.value
        #expect(vm.records.first?.address != nil)
    }

    @Test("순차 처리 — geocoder에 동시 호출이 없다")
    func geocoderCalledSequentially() async throws {
        let (vm, geocodeMock, repo) = makeSUT()
        let records = (0..<3).map { _ in FieldRecord.make() }
        repo.recordsToReturn = records
        vm.extracted = (0..<3).map { _ in makePhotoWithGPS() }

        await vm.save()
        await vm.addressTask?.value

        #expect(await geocodeMock.maxConcurrent <= 1)
    }
}

// MARK: - Helpers

private func makePhotoWithGPS() -> Photo {
    Photo(
        imageData: Data([0xFF, 0xD8]),
        metadata: PhotoMetadata(
            coordinate: Coordinate(latitude: 37.5, longitude: 127.0),
            capturedAt: nil
        )
    )
}

private final class StubExtractor: PhotoMetadataExtracting, @unchecked Sendable {
    func extract(from imageData: Data) async throws -> PhotoMetadata {
        PhotoMetadata(coordinate: nil, capturedAt: nil)
    }
}

/// ViewModel 테스트 전용 FakeRepository.
/// save() → fetchAll() 시 미리 세팅한 recordsToReturn을 반환한다.
@MainActor
final class FakeFieldRecordRepositoryForViewModel: FieldRecordRepository {
    var recordsToReturn: [FieldRecord] = []
    var createCallCount = 0
    var updateAddressCallCount = 0

    func create(_ record: FieldRecord) async throws { createCallCount += 1 }
    func fetchAll() async throws -> [FieldRecord] { recordsToReturn }
    func update(_ record: FieldRecord) async throws {}
    func updateAddress(id: UUID, address: String) async throws {
        updateAddressCallCount += 1
        if let i = recordsToReturn.firstIndex(where: { $0.id == id }) {
            recordsToReturn[i].address = address
        }
    }
    func delete(id: UUID) async throws {}
}

// MARK: - MockGeocodingService 헬퍼

extension MockGeocodingService {
    func setBehavior(_ newBehavior: Behavior) {
        behavior = newBehavior
    }
}
