//
//  LocationWebRepository.swift
//  augment-ios-interview-take-home
//
//  Created by Alan Leatherman on 8/31/25.
//

import Foundation
import CoreLocation

final class LocationWebRepository: NSObject, LocationRepositoryProtocol, @unchecked Sendable {
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() async {
        guard locationManager.authorizationStatus == .notDetermined else {
            return
        }
        
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else {
            throw LocationError.permissionDenied
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            
            // Set timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if self.locationContinuation != nil {
                    self.locationContinuation?.resume(throwing: LocationError.timeout)
                    self.locationContinuation = nil
                }
            }
            
            locationManager.requestLocation()
        }
    }
    
    func getAuthorizationStatus() -> CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationWebRepository: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: LocationError.locationUnavailable(error))
        locationContinuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Handle authorization changes if needed
        // This could be used to update app state
    }
}