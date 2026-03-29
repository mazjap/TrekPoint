import MapboxMaps

enum GroupedMapContentCoordinateIntent {
    case moveAnnotation(annotation: AnnotationData, toCoordinate: CLLocationCoordinate2D)
    case moveWorkingAnnotation(toCoordinate: CLLocationCoordinate2D)
    case moveWorkingPolyline(pointAtIndex: Int, toCoordinate: CLLocationCoordinate2D)
}

enum GroupedMapContentIntent {
    case moveAnnotation(annotation: AnnotationData, toPoint: CGPoint)
    case moveWorkingAnnotation(toPoint: CGPoint)
    case moveWorkingPolyline(pointAtIndex: Int, toPoint: CGPoint)

    func toCoordinateIntent(proxy: MapProxy, annotations: [AnnotationData], polylines: [PolylineData]) -> GroupedMapContentCoordinateIntent? {
        switch self {
        case let .moveAnnotation(annotation, point):
            guard let coordinate = proxy.map?.coordinate(for: point) else {
                return nil
            }

            return .moveAnnotation(annotation: annotation, toCoordinate: coordinate)
        case let .moveWorkingAnnotation(point):
            guard let coordinate = proxy.map?.coordinate(for: point) else {
                return nil
            }

            return .moveWorkingAnnotation(toCoordinate: coordinate)
        case let .moveWorkingPolyline(index, point):
            guard let coordinate = proxy.map?.coordinate(for: point) else {
                return nil
            }

            return .moveWorkingPolyline(pointAtIndex: index, toCoordinate: coordinate)
        }
    }
}
