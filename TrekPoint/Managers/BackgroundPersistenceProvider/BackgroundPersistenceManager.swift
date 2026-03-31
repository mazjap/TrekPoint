import Foundation
import OSLog
import SwiftData
import CoreLocation
import Dependencies

@Observable
class BackgroundPersistenceManager {
    @ObservationIgnored @Dependency(\.modelContainer) private var container
    private let logger = Logger(subsystem: "BackgroundPersistenceManager", category: "TrekPoint")
    
    func saveLocationInBackground(_ location: TemporaryTrackingLocation, completion: @escaping () -> Void) {
        Task {
            let context = ModelContext(container)
            
            let pendingLocation = PendingTrackingLocation(
                trackingID: location.trackingID,
                coordinate: location.coordinate,
                timestamp: location.timestamp
            )
            
            context.insert(pendingLocation)
            
            do {
                try context.save()
                completion()
            } catch {
                logger.error("Failed to save location: \(error)")
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
            return pendingLocations.map { CLLocationCoordinate2D($0.coordinate) }
        } catch {
            logger.error("Failed to fetch pending locations: \(error)")
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
            logger.error("Failed to clear pending locations: \(error)")
        }
    }
    
    func clearAllPendingLocations() {
        let context = ModelContext(container)
        
        do {
            try context.delete(model: PendingTrackingLocation.self)
            try context.save()
            print(try! context.fetch(FetchDescriptor<PendingTrackingLocation>()))
        } catch {
            logger.error("Failed to clear pending locations: \(error)")
        }
    }
}
