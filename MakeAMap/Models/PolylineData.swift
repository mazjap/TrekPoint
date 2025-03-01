import Foundation
import SwiftData

typealias PolylineData = CurrentModelVersion.PolylineData

extension ModelVersion1_0_0 {
    @Model
    final class PolylineData: PersistentEditableModel, Identifiable {
        var id: UUID
        var createdAt: Date
        var lastEditedAt: Date
        var title: String
        var subtitle: String?
        var coordinates: [Coordinate]
        
        init(title: String, subtitle: String? = nil, coordinates: [Coordinate], id: UUID = UUID(), createdAt: Date = .now, lastEditedAt: Date = .now) {
            self.title = title
            self.subtitle = subtitle
            self.coordinates = coordinates
            self.id = id
            self.createdAt = createdAt
            self.lastEditedAt = lastEditedAt
        }
    }
    
    struct OrderedCoordinate: Identifiable {
        let index: Int
        let coordinate: Coordinate
        
        var id: Int { index }
    }
}
