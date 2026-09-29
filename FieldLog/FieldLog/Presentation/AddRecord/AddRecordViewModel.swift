
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

    init(
        extractMetadata: ExtractPhotoMetadataUseCase,
        createRecord: CreateFieldRecordUseCase,
        fetchRecords: FetchFieldRecordsUseCase
    ) {
        self.extractMetadata = extractMetadata
        self.createRecord = createRecord
        self.fetchRecords = fetchRecords
    }

    /// EXIF GPS가 있어 자동 저장 가능한 사진 수. UI 표시용.
    var autoLocatableCount: Int {
        extracted.filter { $0.metadata.coordinate != nil }.count
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
    func save() async {
        isSaving = true
        defer { isSaving = false }

        for record in extracted.compactMap({ FieldRecord(autoFrom: $0) }) {
            try? await createRecord(record)
        }
        extracted = []
        pickerItems = []
        await loadRecords()
    }
}
