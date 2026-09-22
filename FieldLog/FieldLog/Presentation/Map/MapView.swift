
//  MapView.swift
//  FieldLog

import MapKit
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
    MapView(
        addRecordViewModel: AddRecordViewModel(
            extractMetadata: ExtractPhotoMetadataUseCase(
                extractor: ImageIOPhotoMetadataExtractor()
            )
        )
    )
}
