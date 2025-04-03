import struct CoreLocation.CLLocationCoordinate2D

protocol AnnotationProvider {
    var clCoordinate: CLLocationCoordinate2D { get }
    var title: String { get }
    var attachments: [Attachment] { get }
    var userDescription: String { get }
    var tag: MapFeatureTag { get }
}

extension AnnotationData: AnnotationProvider {
    var tag: MapFeatureTag { .annotation(id) }
}

struct WorkingAnnotation: AnnotationProvider, Hashable {
    var coordinate: Coordinate
    var title: String
    var attachments: [Attachment] = []
    var userDescription: String = ""
    let tag = MapFeatureTag.newFeature
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(coordinate)
    }
    
    static let example = WorkingAnnotation(coordinate: Coordinate(latitude: 40.049478, longitude: -111.670115), title: "Home")
}

enum AnnotationType: AnnotationProvider {
    case working(WorkingAnnotation)
    case model(AnnotationData)
    
    var clCoordinate: CLLocationCoordinate2D {
        switch self {
        case .working(let annotation):
            annotation.clCoordinate
        case .model(let annotation):
            annotation.clCoordinate
        }
    }
    
    var title: String {
        switch self {
        case .working(let annotation):
            annotation.title
        case .model(let annotation):
            annotation.title
        }
    }
    
    var attachments: [Attachment] {
        switch self {
        case .working(let annotation):
            annotation.attachments
        case .model(let annotation):
            annotation.attachments
        }
    }
    
    var userDescription: String {
        switch self {
        case .working(let annotation):
            annotation.userDescription
        case .model(let annotation):
            annotation.userDescription
        }
    }
    
    var tag: MapFeatureTag {
        switch self {
        case .working(let annotation):
            annotation.tag
        case .model(let annotation):
            annotation.tag
        }
    }
}
