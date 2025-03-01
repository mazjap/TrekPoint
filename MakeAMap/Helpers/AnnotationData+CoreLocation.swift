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
        CLLocationCoordinate2D(coordinate)
    }
}
#endif
