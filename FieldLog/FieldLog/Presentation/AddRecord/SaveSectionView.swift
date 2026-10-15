
//  SaveSectionView.swift
//  FieldLog

import SwiftUI

struct SaveSectionView: View {
    let isSaving: Bool
    let saveCount: Int
    let onSave: () -> Void

    var body: some View {
        Section {
            Button {
                onSave()
            } label: {
                if isSaving {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    Text("저장 (\(saveCount)장)")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(saveCount == 0 || isSaving)
        }
    }
}
