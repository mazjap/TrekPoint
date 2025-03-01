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
    
    var id: String {
        switch self {
        case let .annotation(id):
            id.uuidString
        case let .polyline(id):
            id.uuidString
        case .newFeature:
            "new_feature"
        }
    }
}
