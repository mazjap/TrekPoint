import CoreLocation

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
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0 // Filter updates less than 5 meters
        
        if UserDefaults.standard.bool(forKey: "is_user_location_active") {
            showUserLocation()
        }
    }
    
    func showUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            guard locationManager.location != nil else { return }
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
        locationManager.startUpdatingLocation()
        isTracking = true
        
        return locationManager.location?.coordinate ?? lastLocation?.coordinate
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
}
