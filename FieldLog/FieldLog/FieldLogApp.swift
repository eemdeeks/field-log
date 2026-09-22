
//  FieldLogApp.swift
//  FieldLog

import SwiftUI

@main
struct FieldLogApp: App {
    private let addRecordViewModel = AddRecordViewModel(
        extractMetadata: ExtractPhotoMetadataUseCase(
            extractor: ImageIOPhotoMetadataExtractor()
        )
    )

    var body: some Scene {
        WindowGroup {
            ContentView(addRecordViewModel: addRecordViewModel)
        }
    }
}
