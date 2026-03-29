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
    
    init?(rawValue: String) {
        if rawValue == "working_annotation" {
            self = .workingAnnotation
        } else if rawValue == "working_polyline" {
            self = .workingPolyline
        } else {
            let splitString = rawValue.split(separator: "_")
            
            guard splitString.count == 2,
                let uuid = UUID(uuidString: String(splitString[1]))
            else {
                return nil
            }
            
            if splitString[0] == "annotation" {
                self = .annotation(uuid)
            } else if splitString[0] == "polyline" {
                self = .polyline(uuid)
            } else {
                return nil
            }
        }
    }
    
    var id: String {
        switch self {
        case let .annotation(id):
            "annotation_" + id.uuidString
        case let .polyline(id):
            "polyline_" + id.uuidString
        case .workingAnnotation:
            "working_annotation"
        case .workingPolyline:
            "working_polyline"
        }
    }
}
