import Foundation
import SwiftData

typealias AnnotationData = CurrentModelVersion.AnnotationData

// MARK: - 1.1.0

// Changes:
// - Added attachments
extension ModelInformation.ModelVersion1_1_0 {
    @Model
    final class AnnotationData: PersistentEditableModel, Identifiable {
        var title: String
        var userDescription: String
        var id: UUID
        var createdAt: Date
        var lastEditedAt: Date
        var coordinate: Coordinate
        var attachments: [Attachment] = []
        
        init(title: String, userDescription: String = "", coordinate: Coordinate, attachments: [Attachment] = [], id: UUID = UUID(), createdAt: Date = .now, lastEditedAt: Date = .now) {
            self.title = title
            self.userDescription = userDescription
            self.coordinate = coordinate
            self.attachments = attachments
            self.id = id
            self.createdAt = createdAt
            self.lastEditedAt = lastEditedAt
        }
    }
}

// MARK: - 1.0.0

extension ModelInformation.ModelVersion1_0_0 {
    @Model
    final class AnnotationData: PersistentEditableModel, Identifiable {
        var title: String
        var userDescription: String
        var id: UUID
        var createdAt: Date
        var lastEditedAt: Date
        var coordinate: Coordinate
        
        init(title: String, userDescription: String = "", coordinate: Coordinate, id: UUID = UUID(), createdAt: Date = .now, lastEditedAt: Date = .now) {
            self.title = title
            self.userDescription = userDescription
            self.coordinate = coordinate
            self.id = id
            self.createdAt = createdAt
            self.lastEditedAt = lastEditedAt
        }
    }
}
