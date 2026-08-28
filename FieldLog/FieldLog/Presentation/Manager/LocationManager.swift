//
//  LocationManager.swift
//  FieldLog
//
//  Created by 박승찬 on 8/27/26.
//

import Combine
import CoreLocation
import Foundation

final class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    func requestPermissionIfNeeded() {
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

}

extension LocationManager: CLLocationManagerDelegate { }
