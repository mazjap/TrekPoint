import struct CoreLocation.CLLocationCoordinate2D

protocol PolylineProvider {
    var clCoordinates: [CLLocationCoordinate2D] { get }
    var title: String { get }
    var tag: MapFeatureTag { get }
}

extension PolylineData: PolylineProvider {
    var tag: MapFeatureTag { .polyline(id) }
}

struct WorkingPolyline: PolylineProvider {
    var coordinates: [Coordinate]
    var title: String
    let tag = MapFeatureTag.newFeature
    var clCoordinates: [CLLocationCoordinate2D] { coordinates.map { CLLocationCoordinate2D($0) } }
    
    static let example: WorkingPolyline = .init(
        coordinates: [
            Coordinate(latitude: 40.051493, longitude: -111.671492),
            Coordinate(latitude: 40.051484, longitude: -111.671493),
            Coordinate(latitude: 40.051502, longitude: -111.673455),
            Coordinate(latitude: 40.051502, longitude: -111.673455),
            Coordinate(latitude: 40.05307, longitude: -111.673456),
            Coordinate(latitude: 40.05307, longitude: -111.673456),
            Coordinate(latitude: 40.053037, longitude: -111.673457),
            Coordinate(latitude: 40.053049, longitude: -111.673589),
            Coordinate(latitude: 40.053081, longitude: -111.674378),
            Coordinate(latitude: 40.053094, longitude: -111.675689),
            Coordinate(latitude: 40.053102, longitude: -111.676014),
            Coordinate(latitude: 40.053083, longitude: -111.677388),
            Coordinate(latitude: 40.053083, longitude: -111.677388),
            Coordinate(latitude: 40.053083, longitude: -111.677428),
            Coordinate(latitude: 40.05329, longitude: -111.677435),
            Coordinate(latitude: 40.054132, longitude: -111.677422),
            Coordinate(latitude: 40.054242, longitude: -111.67752),
            Coordinate(latitude: 40.054242, longitude: -111.67752),
            Coordinate(latitude: 40.054334, longitude: -111.677602),
            Coordinate(latitude: 40.054473, longitude: -111.677389),
            Coordinate(latitude: 40.054717, longitude: -111.677057),
            Coordinate(latitude: 40.054612, longitude: -111.676913),
            Coordinate(latitude: 40.054612, longitude: -111.676913),
            Coordinate(latitude: 40.054583, longitude: -111.676844),
            Coordinate(latitude: 40.054563, longitude: -111.675499),
            Coordinate(latitude: 40.054563, longitude: -111.675499),
            Coordinate(latitude: 40.054564, longitude: -111.67447),
            Coordinate(latitude: 40.054547, longitude: -111.673407),
            Coordinate(latitude: 40.054556, longitude: -111.673407),
            Coordinate(latitude: 40.054556, longitude: -111.673407),
            Coordinate(latitude: 40.054547, longitude: -111.673407),
            Coordinate(latitude: 40.054563, longitude: -111.673135),
            Coordinate(latitude: 40.054558, longitude: -111.67151),
            Coordinate(latitude: 40.054558, longitude: -111.67151),
            Coordinate(latitude: 40.05456, longitude: -111.671438),
            Coordinate(latitude: 40.053061, longitude: -111.67145),
            Coordinate(latitude: 40.053061, longitude: -111.67145),
            Coordinate(latitude: 40.053005, longitude: -111.67145),
            Coordinate(latitude: 40.053003, longitude: -111.669449),
            Coordinate(latitude: 40.053003, longitude: -111.669449),
            Coordinate(latitude: 40.052977, longitude: -111.667432),
            Coordinate(latitude: 40.052977, longitude: -111.667432),
            Coordinate(latitude: 40.052978, longitude: -111.667434),
            Coordinate(latitude: 40.051468, longitude: -111.667437)
        ],
        title: "Walking Path"
    )
}

