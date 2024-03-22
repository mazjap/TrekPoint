import Foundation
import SwiftData

@Model
final class AnnotationData: Identifiable {
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
}

#if canImport(CoreLocation)
import CoreLocation

extension AnnotationData {
    convenience init(title: String, coordinate: CLLocationCoordinate2D) {
        self.init(title: title, coordinate: Coordinate(coordinate))
    }
    
    convenience init(title: String, coordinate: CLLocationCoordinate2D, id: UUID, createdAt: Date, lastEditedAt: Date) {
        self.init(title: title, coordinate: Coordinate(coordinate), id: id, createdAt: createdAt, lastEditedAt: lastEditedAt)
    }
    
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
#endif
