
//  ExtractedResultsSectionView.swift
//  FieldLog

import SwiftUI

struct ExtractedResultsSectionView: View {
    let photos: [Photo]

    var body: some View {
        Section("추출된 정보 (\(photos.count)장)") {
            ForEach(photos) { photo in
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
}
