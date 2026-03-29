import struct CoreLocation.CLLocationCoordinate2D
import Turf

protocol AnnotationProvider {
    var clCoordinate: CLLocationCoordinate2D { get }
    var title: String { get }
    var attachments: [Attachment] { get }
    var userDescription: String { get }
    var tag: MapFeatureTag { get }
}

extension AnnotationProvider {
    var feature: Feature {
        var feature = Feature(geometry: .point(Point(clCoordinate)))
        feature.identifier = FeatureIdentifier(tag.id)
        feature.properties = [
            "title" : .string(title),
            "categoryIcon" : .string("star")
        ]
        
        return feature
    }
}

extension AnnotationData: AnnotationProvider {
    var tag: MapFeatureTag { .annotation(id) }
}

struct WorkingAnnotation: AnnotationProvider, Hashable {
    var coordinate: Coordinate
    var title: String
    var attachments: [Attachment] = []
    var userDescription: String = ""
    let tag = MapFeatureTag.workingAnnotation
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(coordinate)
    }
    
    static let example = WorkingAnnotation(coordinate: Coordinate(latitude: 40.049478, longitude: -111.670115), title: "Home")
}

