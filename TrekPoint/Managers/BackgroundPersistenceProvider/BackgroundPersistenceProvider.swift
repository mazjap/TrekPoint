import CoreLocation
import Dependencies

protocol BackgroundPersistenceProvider {
    func saveLocationInBackground(_ location: TemporaryTrackingLocation, completion: @escaping () -> Void)
    func getPendingLocations(for trackingID: UUID) -> [CLLocationCoordinate2D]
    func clearPendingLocations(for trackingID: UUID)
}

extension BackgroundPersistenceManager: BackgroundPersistenceProvider {}

enum BackgroundPersistenceProviderKey: DependencyKey {
    static let liveValue: any BackgroundPersistenceProvider = BackgroundPersistenceManager()
}

extension DependencyValues {
    var backgroundPersistenceProvider: any BackgroundPersistenceProvider {
        get { self[BackgroundPersistenceProviderKey.self] }
        set { self[BackgroundPersistenceProviderKey.self] = newValue }
    }
}
