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
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Only notify for significant location changes (100 meters)
    }
    
    private var permissionContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    
    func requestLocationPermission() async {
        let currentStatus = locationManager.authorizationStatus
        
        // If already authorized or denied, return immediately
        guard currentStatus == .notDetermined else {
            return
        }
        
        // Wait for permission response
        let _ = await withCheckedContinuation { continuation in
            self.permissionContinuation = continuation
            
            // Add timeout for permission request
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                if self.permissionContinuation != nil {
                    self.permissionContinuation?.resume(returning: self.locationManager.authorizationStatus)
                    self.permissionContinuation = nil
                }
            }
            
            locationManager.requestWhenInUseAuthorization()
        }
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
    
    // MARK: - Location Monitoring
    
    nonisolated func startLocationMonitoring(onLocationUpdate: @escaping (CLLocation) -> Void) {
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else {
            return
        }
        
        locationUpdateHandler = onLocationUpdate
        locationManager.startUpdatingLocation()
    }
    
    nonisolated func stopLocationMonitoring() {
        locationUpdateHandler = nil
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationWebRepository: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        // Handle one-time location request
        if let continuation = locationContinuation {
            continuation.resume(returning: location)
            locationContinuation = nil
        }
        
        // Handle continuous location monitoring
        locationUpdateHandler?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: LocationError.locationUnavailable(error))
        locationContinuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Resume permission continuation if waiting
        if let continuation = permissionContinuation {
            continuation.resume(returning: manager.authorizationStatus)
            permissionContinuation = nil
        }
    }
}