import CoreLocation
import SwiftData

struct TemporaryTrackingLocation {
    let trackingID: UUID
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

@Model
final class PendingTrackingLocation {
    var trackingID: UUID
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    
    init(trackingID: UUID, latitude: Double, longitude: Double, timestamp: Date) {
        self.trackingID = trackingID
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }
}

class PersistenceController {
    static let shared = PersistenceController()
    
    private let container: ModelContainer
    
    private init() {
        do {
            container = try ModelContainer(for: Schema(CurrentModelVersion.models))
        } catch {
            fatalError("Failed to initialize CoreData: \(error)")
        }
    }
    
    func saveLocationInBackground(_ location: TemporaryTrackingLocation, completion: @escaping () -> Void) {
        Task {
            let context = ModelContext(container)
            
            let pendingLocation = PendingTrackingLocation(
                trackingID: location.trackingID,
                latitude: location.latitude,
                longitude: location.longitude,
                timestamp: location.timestamp
            )
            
            context.insert(pendingLocation)
            
            do {
                try context.save()
                completion()
            } catch {
                print("Failed to save location: \(error)")
                completion()
            }
        }
    }
    
    func getPendingLocations(for trackingID: UUID) -> [CLLocationCoordinate2D] {
        let context = ModelContext(container)
        let predicate = #Predicate<PendingTrackingLocation> { $0.trackingID == trackingID }
        let descriptor = FetchDescriptor<PendingTrackingLocation>(predicate: predicate, sortBy: [SortDescriptor(\.timestamp)])
        
        do {
            let pendingLocations = try context.fetch(descriptor)
            return pendingLocations.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        } catch {
            print("Failed to fetch pending locations: \(error)")
            return []
        }
    }
    
    func clearPendingLocations(for trackingID: UUID) {
        let context = ModelContext(container)
        let predicate = #Predicate<PendingTrackingLocation> { $0.trackingID == trackingID }
        let descriptor = FetchDescriptor<PendingTrackingLocation>(predicate: predicate)
        
        do {
            let pendingLocations = try context.fetch(descriptor)
            for location in pendingLocations {
                context.delete(location)
            }
            try context.save()
        } catch {
            print("Failed to clear pending locations: \(error)")
        }
    }
}
