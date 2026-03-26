enum MapButtonIntent {
    // Annotation
    case beginAnnotationCreation
    case confirmAnnotation
    case cancelAnnotation
    case undoAnnotation
    
    // Polyline
    case beginPolylineDrawing
    case confirmPolyline
    case cancelPolyline
    case undoPolyline
    
    // Tracking
    case beginTracking
    case confirmTrackedPolyline
    case cancelTracking
    
    // Location
    case showUserLocation
    case hideUserLocation
}

struct AnnotationButtonState {
    let isShowingOptions: Bool
    let canUndo: Bool
}

struct PolylineButtonState {
    let isDrawing: Bool
    let isTracking: Bool
    let isShowingOptions: Bool
    let canUndo: Bool
}

struct LocationButtonState {
    let isActive: Bool
}
