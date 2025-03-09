import CoreLocation
import UIKit

@Observable
class LocationTrackingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    var lastLocation: CLLocation?
    var isTracking = false
    private(set) var isUserLocationActive: Bool = false {
        didSet {
            UserDefaults.standard.set(isUserLocationActive, forKey: "is_user_location_active")
        }
    }
    
    // Add tracking ID to identify the ongoing track session
    private var activeTrackingID: UUID?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0 // Filter updates less than 5 meters
        
        locationManager.allowsBackgroundLocationUpdates = true
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
    }
    
    func startTracking() -> CLLocationCoordinate2D? {
        activeTrackingID = UUID()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 2.0
        
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
        locationManager.distanceFilter = 5.0
        
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
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp
        )
        
        PersistenceController.shared.saveLocationInBackground(temporaryLocation) {
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
}
