
//  MapView.swift
//  FieldLog

import MapKit
import SwiftData
import SwiftUI

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    let addRecordViewModel: AddRecordViewModel

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
        }
        .mapControls {
            MapCompass()
            MapUserLocationButton()
        }
        .onAppear {
            locationManager.requestPermissionIfNeeded()
        }
        .sheet(isPresented: .constant(true)) {
            AddRecordSheetView(viewModel: addRecordViewModel)
                .presentationDetents([.height(120), .medium, .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .interactiveDismissDisabled()
        }
    }
}

#Preview {
    @MainActor func makeViewModel() -> AddRecordViewModel {
        let container = try! ModelContainer(for: FieldRecordModel.self, PhotoModel.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let dataSource = FieldRecordSwiftDataSource(context: container.mainContext)
        let repository = FieldRecordRepositoryImpl(local: dataSource)
        return AddRecordViewModel(
            extractMetadata: ExtractPhotoMetadataUseCase(extractor: ImageIOPhotoMetadataExtractor()),
            createRecord: CreateFieldRecordUseCase(repository: repository)
        )
    }
    return MapView(addRecordViewModel: makeViewModel())
}
