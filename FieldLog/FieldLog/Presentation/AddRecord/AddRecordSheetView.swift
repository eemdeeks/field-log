
//  AddRecordSheetView.swift
//  FieldLog

import PhotosUI
import SwiftUI

struct AddRecordSheetView: View {
    @Bindable var viewModel: AddRecordViewModel

    var body: some View {
        List {
            photoPickerSection
            if !viewModel.extracted.isEmpty {
                extractedResultsSection
            }
        }
        .onChange(of: viewModel.pickerItems) {
            Task { await viewModel.handlePickerChange() }
        }
    }

    private var photoPickerSection: some View {
        Section {
            PhotosPicker(
                selection: $viewModel.pickerItems,
                matching: .images
            ) {
                Label("사진을 추가하여 지도에 기록하기", systemImage: "photo.badge.plus")
            }
        }
    }

    private var extractedResultsSection: some View {
        Section("추출된 정보 (\(viewModel.extracted.count)장)") {
            ForEach(viewModel.extracted.indices, id: \.self) { index in
                let metadata = viewModel.extracted[index]
                VStack(alignment: .leading, spacing: 4) {
                    if let coord = metadata.coordinate {
                        Text("위도 \(coord.latitude, format: .number.precision(.fractionLength(5))), 경도 \(coord.longitude, format: .number.precision(.fractionLength(5)))")
                    } else {
                        Text("GPS 없음").foregroundStyle(.secondary)
                    }
                    if let date = metadata.capturedAt {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
