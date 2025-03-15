import Foundation
import SwiftData

typealias PolylineData = CurrentModelVersion.PolylineData

// MARK: - 1.1.0

extension ModelInformation.ModelVersion1_1_0 {
    @Model
    final class PolylineData: PersistentEditableModel, Identifiable {
        var title: String
        var userDescription: String
        var coordinates: [Coordinate]
        var isLocationTracked: Bool
        var id: UUID
        var createdAt: Date
        var lastEditedAt: Date
        
        init(title: String, userDescription: String = "", coordinates: [Coordinate], isLocationTracked: Bool, id: UUID = UUID(), createdAt: Date = .now, lastEditedAt: Date = .now) {
            self.title = title
            self.userDescription = userDescription
            self.coordinates = coordinates
            self.isLocationTracked = isLocationTracked
            self.id = id
            self.createdAt = createdAt
            self.lastEditedAt = lastEditedAt
        }
    }
}

// MARK: - 1.0.0

extension ModelInformation.ModelVersion1_0_0 {
    @Model
    final class PolylineData: PersistentEditableModel, Identifiable {
        var title: String
        var userDescription: String
        var coordinates: [Coordinate]
        var isLocationTracked: Bool
        var id: UUID
        var createdAt: Date
        var lastEditedAt: Date
        
        init(title: String, userDescription: String = "", coordinates: [Coordinate], isLocationTracked: Bool, id: UUID = UUID(), createdAt: Date = .now, lastEditedAt: Date = .now) {
            self.title = title
            self.userDescription = userDescription
            self.coordinates = coordinates
            self.isLocationTracked = isLocationTracked
            self.id = id
            self.createdAt = createdAt
            self.lastEditedAt = lastEditedAt
        }
    }
}
