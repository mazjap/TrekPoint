import CoreLocation
import Dependencies

protocol LocationManagerProtocol: AnyObject {
    var delegate: CLLocationManagerDelegate? { get set }
    var authorizationStatus: CLAuthorizationStatus { get }
    var location: CLLocation? { get }
    var desiredAccuracy: Double { get set }
    var distanceFilter: Double { get set }
    var allowsBackgroundLocationUpdates: Bool { get set }
    var showsBackgroundLocationIndicator: Bool { get set }
    var pausesLocationUpdatesAutomatically: Bool { get set }
    
    func requestAlwaysAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

extension CLLocationManager: LocationManagerProtocol {}

enum LocationManagerProviderKey: DependencyKey {
    static var liveValue: any LocationManagerProtocol { CLLocationManager() }
}

extension DependencyValues {
    var locationManagerProvider: any LocationManagerProtocol {
        get { self[LocationManagerProviderKey.self] }
        set { self[LocationManagerProviderKey.self] = newValue }
    }
}
