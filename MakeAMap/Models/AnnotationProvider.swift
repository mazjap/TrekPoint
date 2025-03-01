import struct CoreLocation.CLLocationCoordinate2D

protocol AnnotationProvider {
    var clCoordinate: CLLocationCoordinate2D { get }
    var title: String { get }
    var tag: MapFeatureTag { get }
}

extension AnnotationData: AnnotationProvider {
    var tag: MapFeatureTag { .annotation(id) }
}

struct WorkingAnnotation: AnnotationProvider {
    var coordinate: Coordinate
    var title: String
    let tag = MapFeatureTag.newFeature
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(coordinate)
    }
    
    static let example = WorkingAnnotation(coordinate: Coordinate(latitude: 40.049478, longitude: -111.670115), title: "Home")
}
