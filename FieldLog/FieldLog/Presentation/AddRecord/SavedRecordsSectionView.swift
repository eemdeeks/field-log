
//  SavedRecordsSectionView.swift
//  FieldLog

import SwiftUI

struct SavedRecordsSectionView: View {
    let records: [FieldRecord]

    var body: some View {
        Section("저장된 기록 (\(records.count)장)") {
            ForEach(records) { record in
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.address ?? "주소 확인 중...")
                    Text("위도 \(record.coordinate.latitude, format: .number.precision(.fractionLength(5))), 경도 \(record.coordinate.longitude, format: .number.precision(.fractionLength(5)))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
