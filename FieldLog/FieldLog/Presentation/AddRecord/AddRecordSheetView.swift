
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
                saveSection
            }
            if !viewModel.records.isEmpty {
                savedRecordsSection
            }
        }
        .task { await viewModel.loadRecords() }
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
            ForEach(viewModel.extracted, id: \.imageData) { photo in
                let metadata = photo.metadata
                VStack(alignment: .leading, spacing: 4) {
                    if let coord = metadata.coordinate {
                        Text("위도 \(coord.latitude, format: .number.precision(.fractionLength(5))), 경도 \(coord.longitude, format: .number.precision(.fractionLength(5)))")
                    } else {
                        Text("위치 없음 · 지금은 저장 불가")
                            .foregroundStyle(.secondary)
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

    private var savedRecordsSection: some View {
        Section("저장된 기록 (\(viewModel.records.count)장)") {
            ForEach(viewModel.records) { record in
                VStack(alignment: .leading, spacing: 4) {
                    Text("위도 \(record.coordinate.latitude, format: .number.precision(.fractionLength(5))), 경도 \(record.coordinate.longitude, format: .number.precision(.fractionLength(5)))")
                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                Task { await viewModel.save() }
            } label: {
                if viewModel.isSaving {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    Text("저장 (\(viewModel.autoLocatableCount)장)")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.autoLocatableCount == 0 || viewModel.isSaving)
        }
    }
}
