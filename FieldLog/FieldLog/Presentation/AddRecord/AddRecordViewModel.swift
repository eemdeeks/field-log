
//  AddRecordViewModel.swift
//  FieldLog

import PhotosUI
import SwiftUI

@MainActor
@Observable
final class AddRecordViewModel {
    var pickerItems: [PhotosPickerItem] = []
    var extracted: [PhotoMetadata] = []
    var isExtracting = false

    private let extractMetadata: ExtractPhotoMetadataUseCase

    init(extractMetadata: ExtractPhotoMetadataUseCase) {
        self.extractMetadata = extractMetadata
    }

    /// PhotosPickerItem → Data → PhotoMetadata 순으로 변환.
    /// 한 장 실패해도 나머지는 유지 (try?로 개별 처리).
    func handlePickerChange() async {
        isExtracting = true
        defer { isExtracting = false }

        var results: [PhotoMetadata] = []
        for item in pickerItems {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            if let metadata = try? await extractMetadata(data) {
                print(metadata)
                results.append(metadata)
            }
        }
        extracted = results
    }
}
