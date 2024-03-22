import Foundation

struct Coordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double
}

import CoreLocation

extension Coordinate {
    init(_ coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
