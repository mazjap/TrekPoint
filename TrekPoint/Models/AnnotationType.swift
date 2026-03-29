import struct CoreLocation.CLLocationCoordinate2D

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
