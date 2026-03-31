import CoreLocation
import UIKit
import Dependencies

enum LocationTrackingManagerKey: DependencyKey {
    static let liveValue = LocationTrackingManager()
}

extension DependencyValues {
    var locationTrackingManager: LocationTrackingManager {
        get { self[LocationTrackingManagerKey.self] }
        set { self[LocationTrackingManagerKey.self] = newValue }
    }
}

@Observable
@MainActor
class LocationTrackingManager: NSObject, CLLocationManagerDelegate {
    var lastLocation: CLLocation?
    
    @ObservationIgnored @Dependency(\.appSettings) private var appSettings
    @ObservationIgnored @Dependency(\.userDefaultsProvider) private var userDefaults
    @ObservationIgnored @Dependency(\.backgroundPersistenceProvider) private var backgroundManager: BackgroundPersistenceProvider
    @ObservationIgnored @Dependency(\.locationManagerProvider) private var locationManager
    
    nonisolated override init() {
        super.init()
        
        Task { @MainActor in
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 2.0
            
            locationManager.allowsBackgroundLocationUpdates = false
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.showsBackgroundLocationIndicator = false
            
            if appSettings.isUserLocationActive {
                showUserLocation()
            }
        }
    }
    
    func showUserLocation() {
        locationManager.requestAlwaysAuthorization()
        
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            appSettings.isUserLocationActive = true
        case .restricted, .denied, .notDetermined: fallthrough
        @unknown default:
            appSettings.isUserLocationActive = false
        }
    }
    
    func hideUserLocation() {
        appSettings.isUserLocationActive = false
        locationManager.stopUpdatingLocation()
    }
    
    @discardableResult
    func startTracking() -> CLLocationCoordinate2D? {
        appSettings.activeTrackingId = UUID()
        
        let accuracy = appSettings.gpsAccuracy
        
        switch accuracy {
        case .performance:
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = kCLDistanceFilterNone
        case .balanced:
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.distanceFilter = 5
        case .batterySaver:
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 20
        }
        
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        
        locationManager.startUpdatingLocation()
        appSettings.isTrackingActive = true
        
        return locationManager.location?.coordinate ?? lastLocation?.coordinate
    }
    
    func stopTracking() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 2.0
        
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.showsBackgroundLocationIndicator = false
        
        if !appSettings.isUserLocationActive {
            locationManager.stopUpdatingLocation()
        }
        
        appSettings.isTrackingActive = false
        appSettings.activeTrackingId = nil
        
        clearAllPendingLocations()
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            lastLocation = location
            
            if appSettings.isTrackingActive {
                storeLocationInBackground(location)
            }
        }
    }
    
    private func storeLocationInBackground(_ location: CLLocation) {
        guard let trackingID = appSettings.activeTrackingId else { return }
        
        let backgroundTaskID = UIApplication.shared.beginBackgroundTask()
        
        let temporaryLocation = TemporaryTrackingLocation(
            trackingID: trackingID,
            coordinate: Coordinate(location.coordinate),
            timestamp: location.timestamp
        )
        
        backgroundManager.saveLocationInBackground(temporaryLocation) {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
        }
    }
    
    func checkForPendingTracks() -> UUID? {
        return appSettings.activeTrackingId
    }
    
    func getPendingLocations(forTrackingId trackingId: UUID) -> [CLLocationCoordinate2D] {
        backgroundManager.getPendingLocations(for: trackingId)
    }
    
    func clearPendingLocations(for trackingId: UUID) {
        backgroundManager.clearPendingLocations(for: trackingId)
    }
    
    func clearAllPendingLocations() {
        backgroundManager.clearAllPendingLocations()
        
        appSettings.isTrackingActive = false
        appSettings.activeTrackingId = nil
    }
}
