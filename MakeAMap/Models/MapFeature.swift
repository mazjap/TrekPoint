enum MapFeature {
    case annotation(AnnotationData)
    case polyline(PolylineData)
    
    var tag: MapFeatureTag {
        switch self {
        case let .annotation(annotation):
            return .annotation(annotation.id)
        case let .polyline(polyline):
            return .polyline(polyline.id)
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
