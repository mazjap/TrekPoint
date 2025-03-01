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
