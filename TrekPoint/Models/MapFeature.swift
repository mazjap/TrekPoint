enum MapFeature {
    case annotation(any AnnotationProvider)
    case polyline(any PolylineProvider)
    
    var tag: MapFeatureTag {
        switch self {
        case let .annotation(annotation):
            return annotation.tag
        case let .polyline(polyline):
            return polyline.tag
        }
    }
    
    var geometry: MapFeatureGeometry {
        switch self {
        case let .annotation(annotation):
            return .annotation(annotation.clCoordinate)
        case let .polyline(polyline):
            return .polyline(polyline.clCoordinates)
        }
    }
    
    var title: String {
        switch self {
        case let .annotation(annotation):
            return annotation.title
        case let .polyline(polyline):
            return polyline.title
        }
    }
}

import struct CoreLocation.CLLocationCoordinate2D

enum MapFeatureGeometry: Equatable {
    case annotation(CLLocationCoordinate2D)
    case polyline([CLLocationCoordinate2D])
}

import struct Foundation.UUID

enum MapFeatureTag: Hashable, Identifiable {
    case annotation(UUID)
    case polyline(UUID)
    case newFeature
    
    init?(rawValue: String) {
        if rawValue == "new_feature" {
            self = .newFeature
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
        case .newFeature:
            "new_feature"
        }
    }
}
