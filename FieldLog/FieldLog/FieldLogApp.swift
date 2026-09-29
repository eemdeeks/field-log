
//  FieldLogApp.swift
//  FieldLog

import SwiftData
import SwiftUI

@main
struct FieldLogApp: App {
    private let container: ModelContainer
    private let addRecordViewModel: AddRecordViewModel

    @MainActor
    init() {
        do {
            container = try ModelContainer(
                for: FieldRecordModel.self, PhotoModel.self
            )
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }

        let dataSource = FieldRecordSwiftDataSource(context: container.mainContext)
        let repository = FieldRecordRepositoryImpl(local: dataSource)
        addRecordViewModel = AddRecordViewModel(
            extractMetadata: ExtractPhotoMetadataUseCase(extractor: ImageIOPhotoMetadataExtractor()),
            createRecord: CreateFieldRecordUseCase(repository: repository),
            fetchRecords: FetchFieldRecordsUseCase(repository: repository)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(addRecordViewModel: addRecordViewModel)
        }
    }
}
