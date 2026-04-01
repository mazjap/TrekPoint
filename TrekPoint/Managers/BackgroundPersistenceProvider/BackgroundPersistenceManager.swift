import Foundation
import OSLog
import SwiftData
import CoreLocation
import Dependencies

@MainActor
@Observable
class BackgroundPersistenceManager {
    @ObservationIgnored @Dependency(\.modelContainer) private var container
    private let logger = Logger(subsystem: "BackgroundPersistenceManager", category: "TrekPoint")
    
    nonisolated init() {}
    
    func persistLocation(_ location: TemporaryTrackingLocation) {
        let context = container.mainContext
        
        let pendingLocation = PendingTrackingLocation(
            trackingID: location.trackingID,
            coordinate: location.coordinate,
            timestamp: location.timestamp
        )
        
        context.insert(pendingLocation)
        
        do {
            try context.save()
        } catch {
            logger.error("Failed to save location: \(error)")
        }
    }
    
    func getPendingLocations(for trackingID: UUID) -> [CLLocationCoordinate2D] {
        let context = container.mainContext
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
        let context = container.mainContext
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
        let context = container.mainContext
        
        do {
            try context.delete(model: PendingTrackingLocation.self)
            try context.save()
        } catch {
            logger.error("Failed to clear pending locations: \(error)")
        }
    }
}
