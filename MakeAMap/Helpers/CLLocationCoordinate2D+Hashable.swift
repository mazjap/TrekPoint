import CoreLocation

extension CLLocationCoordinate2D: Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    init(_ coordinate: Coordinate) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    static var random: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: .random(in: -90...90), longitude: .random(in: -180...180))
    }
}

extension Coordinate {
    static var random: Coordinate {
        Coordinate(.random)
    }
}
