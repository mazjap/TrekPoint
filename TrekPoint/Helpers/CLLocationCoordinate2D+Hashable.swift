import CoreLocation

extension CLLocationCoordinate2D {
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
