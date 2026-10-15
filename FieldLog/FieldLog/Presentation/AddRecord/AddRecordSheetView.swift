
//  AddRecordSheetView.swift
//  FieldLog

import PhotosUI
import SwiftUI

struct AddRecordSheetView: View {
    @Bindable var viewModel: AddRecordViewModel

    var body: some View {
        List {
            PhotoPickerSectionView(pickerItems: $viewModel.pickerItems)
            if !viewModel.extracted.isEmpty {
                ExtractedResultsSectionView(photos: viewModel.extracted)
                SaveSectionView(
                    isSaving: viewModel.isSaving,
                    saveCount: viewModel.autoLocatableCount,
                    onSave: { Task { await viewModel.save() } }
                )
            }
            if !viewModel.records.isEmpty {
                SavedRecordsSectionView(records: viewModel.records)
            }
        }
        .task { await viewModel.loadRecords() }
        .onChange(of: viewModel.pickerItems) {
            Task { await viewModel.handlePickerChange() }
        }
    }
}
