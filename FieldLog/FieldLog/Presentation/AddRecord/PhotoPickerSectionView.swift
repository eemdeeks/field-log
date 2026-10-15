
//  PhotoPickerSectionView.swift
//  FieldLog

import PhotosUI
import SwiftUI

struct PhotoPickerSectionView: View {
    @Binding var pickerItems: [PhotosPickerItem]

    var body: some View {
        Section {
            PhotosPicker(
                selection: $pickerItems,
                matching: .images
            ) {
                Label("사진을 추가하여 지도에 기록하기", systemImage: "photo.badge.plus")
            }
        }
    }
}
