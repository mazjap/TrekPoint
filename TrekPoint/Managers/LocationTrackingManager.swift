import CoreLocation
import UIKit
import Dependencies

protocol BackgroundPersistenceProtocol {
    func saveLocationInBackground(_ location: TemporaryTrackingLocation, completion: @escaping () -> Void)
    func getPendingLocations(for trackingID: UUID) -> [CLLocationCoordinate2D]
    func clearPendingLocations(for trackingID: UUID)
}

extension BackgroundPersistenceManager: BackgroundPersistenceProtocol {}



@Observable
class LocationTrackingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    var lastLocation: CLLocation?
    var isTracking = false
    
    private var activeTrackingID: UUID?
    private(set) var isUserLocationActive: Bool = false {
        didSet {
            userDefaults.set(isUserLocationActive, forKey: "is_user_location_active")
        }
    }
    
    @ObservationIgnored @Dependency(\.userDefaultsProvider) private var userDefaults
    private let backgroundManager: BackgroundPersistenceProtocol
    @ObservationIgnored @Dependency(\.locationManagerProvider) private var locationManager
    
    init(backgroundPersistenceManager: BackgroundPersistenceProtocol = BackgroundPersistenceManager()) {
        self.backgroundManager = backgroundPersistenceManager
        
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = false
        
        if UserDefaults.standard.bool(forKey: "is_user_location_active") {
            showUserLocation()
        }
    }
    
    func showUserLocation() {
        locationManager.requestAlwaysAuthorization()
        
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            isUserLocationActive = true
        case .restricted, .denied, .notDetermined: fallthrough
        @unknown default:
            isUserLocationActive = false
        }
    }
    
    func hideUserLocation() {
        isUserLocationActive = false
        locationManager.stopUpdatingLocation()
    }
    
    func startTracking() -> CLLocationCoordinate2D? {
        activeTrackingID = UUID()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 5.0
        
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
        
        locationManager.startUpdatingLocation()
        isTracking = true
        
        UserDefaults.standard.set(true, forKey: "is_tracking_active")
        if let trackingID = activeTrackingID {
            UserDefaults.standard.set(trackingID.uuidString, forKey: "active_tracking_id")
        }
        
        return locationManager.location?.coordinate ?? lastLocation?.coordinate
    }
    
    func stopTracking() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 2.0
        
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.showsBackgroundLocationIndicator = false
        
        locationManager.stopUpdatingLocation()
        
        if isUserLocationActive {
            // Restart location tracking with non-background settings
            locationManager.startUpdatingLocation()
        }
        
        isTracking = false
        activeTrackingID = nil
        
        UserDefaults.standard.removeObject(forKey: "is_tracking_active")
        UserDefaults.standard.removeObject(forKey: "active_tracking_id")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        
        if isTracking {
            storeLocationInBackground(location)
        }
    }
    
    private func storeLocationInBackground(_ location: CLLocation) {
        guard let trackingID = activeTrackingID else { return }
        
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
        if UserDefaults.standard.bool(forKey: "is_tracking_active"),
           let trackingIDString = UserDefaults.standard.string(forKey: "active_tracking_id"),
           let trackingID = UUID(uuidString: trackingIDString) {
            activeTrackingID = trackingID
            isTracking = true
            return trackingID
        }
        return nil
    }
    
    func getPendingLocations(forTrackingId trackingId: UUID) -> [CLLocationCoordinate2D] {
        backgroundManager.getPendingLocations(for: trackingId)
    }
    
    func clearPendingLocations(for trackingId: UUID) {
        backgroundManager.clearPendingLocations(for: trackingId)
    }
}
