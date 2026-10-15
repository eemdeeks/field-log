
//  AddRecordViewModel.swift
//  FieldLog

import PhotosUI
import SwiftUI

@MainActor
@Observable
final class AddRecordViewModel {
    var pickerItems: [PhotosPickerItem] = []
    var extracted: [Photo] = []
    var records: [FieldRecord] = []
    var isExtracting = false
    var isSaving = false

    private let extractMetadata: ExtractPhotoMetadataUseCase
    private let createRecord: CreateFieldRecordUseCase
    private let fetchRecords: FetchFieldRecordsUseCase
    private let reverseGeocode: ReverseGeocodeFieldRecordUseCase

    /// 주소 채우기 루프의 간격. 테스트에서 .zero로 주입해 빠르게 실행할 수 있다.
    let addressFillInterval: Duration

    /// 주소 채우기 루프 실행 중 여부. 재진입 가드로 사용한다.
    private var isFilling = false
    /// 진행 중인 주소 채우기 Task. 테스트에서 완료를 기다릴 때 사용.
    var addressTask: Task<Void, Never>?

    init(
        extractMetadata: ExtractPhotoMetadataUseCase,
        createRecord: CreateFieldRecordUseCase,
        fetchRecords: FetchFieldRecordsUseCase,
        reverseGeocode: ReverseGeocodeFieldRecordUseCase,
        addressFillInterval: Duration = .seconds(1)
    ) {
        self.extractMetadata = extractMetadata
        self.createRecord = createRecord
        self.fetchRecords = fetchRecords
        self.reverseGeocode = reverseGeocode
        self.addressFillInterval = addressFillInterval
    }

    /// EXIF GPS가 있어 자동 저장 가능한 사진 수. UI 표시용.
    var autoLocatableCount: Int {
        extracted.count(where: { $0.metadata.coordinate != nil })
    }

    /// PhotosPickerItem → Data → Photo(imageData + metadata) 순으로 변환.
    /// 한 장 실패해도 나머지는 유지 (try?로 개별 처리).
    func handlePickerChange() async {
        isExtracting = true
        defer { isExtracting = false }

        var results: [Photo] = []
        for item in pickerItems {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            if let metadata = try? await extractMetadata(data) {
                results.append(Photo(imageData: data, metadata: metadata))
            }
        }
        extracted = results
    }

    func loadRecords() async {
        records = (try? await fetchRecords()) ?? []
    }

    /// EXIF GPS가 있는 사진만 FieldRecord로 변환해 저장. GPS 없는 사진은 건너뜀.
    /// 저장 후 주소 채우기를 비동기로 시작한다 — 블로킹하지 않음.
    func save() async {
        isSaving = true
        defer { isSaving = false }

        for record in extracted.compactMap({ FieldRecord(autoFrom: $0) }) {
            try? await createRecord(record)
        }
        extracted = []
        pickerItems = []
        await loadRecords()
        startFillingAddresses()
    }

    // MARK: - 주소 채우기 (단일 패스, 메모리 부분 갱신)

    /// 단일 패스: records에서 현재 address == nil인 건만 스냅샷해 순차 변환.
    /// 재진입 가드로 동시 CLGeocoder 호출을 막는다.
    /// 실패 건은 nil로 남고 다음 save() 트리거 시 다시 스냅샷 대상이 된다.
    func startFillingAddresses() {
        guard !isFilling else { return }
        addressTask = Task { await fillLoop() }
    }

    private func fillLoop() async {
        isFilling = true
        defer { isFilling = false }
        let targets = records.filter { $0.address == nil }
        for (index, record) in targets.enumerated() {
            let address = await reverseGeocode(id: record.id, coordinate: record.coordinate)
            // await 후 배열이 바뀌었을 수 있으므로 index가 아니라 id로 재탐색.
            // 해당 id가 삭제됐으면 firstIndex가 nil → 조용히 skip.
            if let address, let i = records.firstIndex(where: { $0.id == record.id }) {
                records[i].address = address
            }
            if index < targets.count - 1 {
                try? await Task.sleep(for: addressFillInterval)
            }
        }
    }
}
