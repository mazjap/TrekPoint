import struct CoreLocation.CLLocationCoordinate2D
import struct Foundation.Date
import struct Foundation.UUID

extension PolylineData {
    convenience init(title: String, userDescription: String = "", coordinates: [CLLocationCoordinate2D], isLocationTracked: Bool, id: UUID = UUID(), createdAt: Date = .now, lastEditedAt: Date = .now) {
        self.init(title: title, userDescription: userDescription, coordinates: coordinates.map { Coordinate($0) }, isLocationTracked: isLocationTracked, id: id, createdAt: createdAt, lastEditedAt: lastEditedAt)
    }
    
    var clCoordinates: [CLLocationCoordinate2D] {
        coordinates.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
}
