import CoreLocation
import SwiftData

typealias PendingTrackingLocation = CurrentModelVersion.PendingTrackingLocation

struct TemporaryTrackingLocation {
    let trackingID: UUID
    let coordinate: Coordinate
    let timestamp: Date
}

extension ModelInformation.ModelVersion1_1_0 {
    @Model
    final class PendingTrackingLocation {
        var trackingID: UUID
        var coordinate: Coordinate
        var timestamp: Date
        
        init(trackingID: UUID, coordinate: Coordinate, timestamp: Date) {
            self.trackingID = trackingID
            self.coordinate = coordinate
            self.timestamp = timestamp
        }
    }
}
