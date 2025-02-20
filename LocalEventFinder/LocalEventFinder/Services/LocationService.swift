//
//  LocationService.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 11/26/24.
//

import CoreLocation

class LocationService: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var currentPlacemark: CLPlacemark?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var lastKnownLocation: CLLocation?
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    override init() {
        authorizationStatus = locationManager.authorizationStatus
        
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1000 // Update location every 1km
        
        // Request permission immediately on init
        print("Requesting location permission")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestPermission() {
        print("Explicitly requesting location permission")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        print("Current authorization status: \(authorizationStatus.rawValue)")
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Starting location updates")
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
            errorMessage = "Location access denied. Please enable in Settings."
        case .notDetermined:
            print("Location permission not determined, requesting...")
            requestPermission()
        @unknown default:
            break
        }
    }
    
    func setManualLocation(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        // Update location immediately
        DispatchQueue.main.async {
            self.location = location
            self.lastKnownLocation = location
        }
        
        // Perform reverse geocoding
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to get address for location"
                    self?.currentPlacemark = nil
                } else if let placemark = placemarks?.first {
                    print("Successfully retrieved placemark: \(placemark)")
                    self?.currentPlacemark = placemark
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    private func updateLocationAndPlacemark(_ location: CLLocation) {
        DispatchQueue.main.async {
            self.location = location
            self.lastKnownLocation = location
            self.errorMessage = nil
        }
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to get address for location"
                    self?.currentPlacemark = nil
                } else if let placemark = placemarks?.first {
                    print("Successfully retrieved placemark: \(placemark)")
                    self?.currentPlacemark = placemark
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            print("Location authorization status changed to: \(self.authorizationStatus.rawValue)")
            
            switch self.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("Location authorized, starting updates")
                self.startUpdatingLocation()
            case .denied, .restricted:
                print("Location access denied")
                self.errorMessage = "Location access denied. Please enable in Settings."
            case .notDetermined:
                print("Location permission not determined, requesting...")
                self.requestPermission()
            @unknown default:
                break
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        updateLocationAndPlacemark(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
        }
    }
}
