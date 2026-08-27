//
//  MapView.swift
//  FieldLog
//
//  Created by 박승찬 on 8/26/26.
//

import MapKit
import SwiftUI

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @Namespace var mapScope

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
    }

}

#Preview {
    MapView()
}
