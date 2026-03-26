import Foundation

enum ResolvedMapFeature: Hashable {
    case annotation(AnnotationData)
    case polyline(PolylineData)
    case workingAnnotation
    case workingPolyline
    
    var tag: MapFeatureTag {
        switch self {
        case let .annotation(annotation):
            annotation.tag
        case let .polyline(polyline):
            polyline.tag
        case .workingPolyline:
            .workingPolyline
        case .workingAnnotation:
            .workingAnnotation
        }
    }
}

enum MapFeatureTag: Hashable, Identifiable {
    case annotation(UUID)
    case polyline(UUID)
    case workingAnnotation
    case workingPolyline
    
    var id: String {
        switch self {
        case let .annotation(id):
            id.uuidString
        case let .polyline(id):
            id.uuidString
        case .workingAnnotation:
            "working_annotation"
        case .workingPolyline:
            "working_polyline"
        }
    }
}
