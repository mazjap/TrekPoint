#if canImport(CoreLocation)
import CoreLocation

extension PolylineData {
    convenience init(title: String, coordinates: [CLLocationCoordinate2D]) {
        self.init(title: title, coordinates: coordinates.map { Coordinate($0) })
    }
    
    convenience init(title: String, coordinates: [CLLocationCoordinate2D], id: UUID, createdAt: Date, lastEditedAt: Date) {
        self.init(title: title, coordinates: coordinates.map { Coordinate($0) }, id: id, createdAt: createdAt, lastEditedAt: lastEditedAt)
    }
    
    var clCoordinates: [CLLocationCoordinate2D] {
        coordinates.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
}
#endif
