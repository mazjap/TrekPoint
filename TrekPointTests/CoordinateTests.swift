@testable import TrekPoint
import Testing
import CoreLocation

struct CoordinateTests {
    @Test(
        "Initialize coordinate from provided latitude and longitude",
        arguments: [(0, 0), (10.83564, 84.52900), (90, 180), (-90, -180), (.infinity, .infinity)]
    )
    func coordinateInitializationFromDouble(lat: Double, lng: Double) {
        let coordinate = Coordinate(latitude: lat, longitude: lng)
        
        #expect(coordinate.latitude == lat)
        #expect(coordinate.longitude == lng)
    }
    
    @Test(
        "Initialize Coordinate from provided CLLocationCoordinate2D",
        arguments: [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 10.83564, longitude: 84.52900),
            CLLocationCoordinate2D(latitude: 90, longitude: 180),
            CLLocationCoordinate2D(latitude: -90, longitude: -180),
            CLLocationCoordinate2D(latitude: .infinity, longitude: .infinity)
        ]
    )
    func coordinateInitializedFromCLLocationCoordinate2D(clCoordinate: CLLocationCoordinate2D) {
        let coordinate = Coordinate(clCoordinate)
        
        #expect(coordinate.latitude == clCoordinate.latitude)
        #expect(coordinate.longitude == clCoordinate.longitude)
    }
}
