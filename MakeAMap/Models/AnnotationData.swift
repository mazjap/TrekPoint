import Foundation
import SwiftData

typealias AnnotationData = CurrentModelVersion.AnnotationData

extension ModelVersion1_0_0 {
    @Model
    final class AnnotationData: PersistentEditableModel, Identifiable {
        var id: UUID
        var createdAt: Date
        var lastEditedAt: Date
        var title: String
        var subtitle: String?
        var coordinate: Coordinate
        
        init(title: String, subtitle: String? = nil, coordinate: Coordinate, id: UUID = UUID(), createdAt: Date = .now, lastEditedAt: Date = .now) {
            self.title = title
            self.subtitle = subtitle
            self.coordinate = coordinate
            self.id = id
            self.createdAt = createdAt
            self.lastEditedAt = lastEditedAt
        }
        
        static let example = AnnotationData(title: "Home", coordinate: Coordinate(latitude: 40.049478, longitude: -111.670115))
    }
}
