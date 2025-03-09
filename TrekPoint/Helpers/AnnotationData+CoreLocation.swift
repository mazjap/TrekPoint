import struct CoreLocation.CLLocationCoordinate2D
import struct Foundation.Date
import struct Foundation.UUID

extension AnnotationData {
    convenience init(title: String, userDescription: String = "", coordinate: CLLocationCoordinate2D, id: UUID = UUID(), createdAt: Date = .now, lastEditedAt: Date = .now) {
        self.init(title: title, userDescription: userDescription, coordinate: Coordinate(coordinate), id: id, createdAt: createdAt, lastEditedAt: lastEditedAt)
    }
    
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(coordinate)
    }
}
