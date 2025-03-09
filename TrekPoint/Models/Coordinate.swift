import Foundation

struct Coordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var id: UUID
    
    init(latitude: Double, longitude: Double, id: UUID = UUID()) {
        self.latitude = latitude
        self.longitude = longitude
        self.id = id
    }
}

import CoreLocation

extension Coordinate {
    init(_ coordinate: CLLocationCoordinate2D, id: UUID = UUID()) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude, id: id)
    }
}
