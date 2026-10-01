
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
            ForEach(addRecordViewModel.records) { record in
                if let thumbnailData = record.photo.thumbnailData {
                    Annotation("", coordinate: record.coordinate.clLocationCoordinate2D) {
                        BannerAnnotationView(thumbnailData: thumbnailData, count: 1)
                    }
                }
            }
        }
        .mapControls {
            MapCompass()
            MapUserLocationButton()
        }
        .onAppear {
            locationManager.requestPermissionIfNeeded()
        }
        .task {
            // 앱 최초 진입 시 1회 로드. 저장 후 갱신은 AddRecordViewModel.save()에 위임.
            await addRecordViewModel.loadRecords()
        }
        .sheet(isPresented: .constant(true)) {
            AddRecordSheetView(viewModel: addRecordViewModel)
                .presentationDetents([.height(120), .medium, .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .interactiveDismissDisabled()
        }
    }
}

// MARK: - MapKit 변환 헬퍼 (UI 레이어에서만 사용)

private extension Coordinate {
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

#Preview {
    @MainActor func makeViewModel() -> AddRecordViewModel {
        let container = try! ModelContainer(for: FieldRecordModel.self, PhotoModel.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let dataSource = FieldRecordSwiftDataSource(context: container.mainContext)
        let repository = FieldRecordRepositoryImpl(local: dataSource)
        return AddRecordViewModel(
            extractMetadata: ExtractPhotoMetadataUseCase(extractor: ImageIOPhotoMetadataExtractor()),
            createRecord: CreateFieldRecordUseCase(
                repository: repository,
                thumbnailGenerator: ImageIOThumbnailGenerator()
            ),
            fetchRecords: FetchFieldRecordsUseCase(repository: repository)
        )
    }
    return MapView(addRecordViewModel: makeViewModel())
}
