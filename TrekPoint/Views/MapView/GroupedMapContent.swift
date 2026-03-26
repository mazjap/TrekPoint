import SwiftUI
import MapKit
import Dependencies

struct GroupedMapContent: MapContent {
    private let annotationState: AnnotationOverlayState
    private let polylineState: PolylineOverlayState
    private let locationState: LocationOverlayState
    private let annotations: [AnnotationData]
    private let polylines: [PolylineData]
    private let onIntent: (GroupedMapContentIntent) -> Void
    
    init(annotationState: AnnotationOverlayState, polylineState: PolylineOverlayState, locationState: LocationOverlayState, annotations: [AnnotationData], polylines: [PolylineData], onIntent: @escaping (GroupedMapContentIntent) -> Void) {
        self.annotationState = annotationState
        self.polylineState = polylineState
        self.locationState = locationState
        self.annotations = annotations
        self.polylines = polylines
        self.onIntent = onIntent
    }
    
    var body: some MapContent {
        if locationState.isActive {
            UserAnnotation()
        }
        
        annotationViews
        
        polylineViews
        
        inProgressPolyline
        
        inProgressPin
    }
    
    private var annotationViews: some MapContent {
        ForEach(annotations) { annotation in
            AnnotationMapOverlay(annotation: annotation, movementEnabled: true, shouldJiggle: false, foregroundColor: .orange) { newPosition in
                onIntent(.moveAnnotation(annotation: annotation, toPoint: newPosition))
            }
        }
    }
    
    private var polylineViews: some MapContent {
        ForEach(polylines) { polyline in
            PolylineMapOverlay(polyline: polyline, strokeColor: polyline.isLocationTracked ? .orange : .red)
        }
    }
    
    @MapContentBuilder
    private var inProgressPin: some MapContent {
        if let newAnnotationLocation = annotationState.workingAnnotation {
            AnnotationMapOverlay(
                annotation: newAnnotationLocation,
                shouldJiggle: annotationState.isShowingOptions,
                foregroundColor: .orange,
                fillColor: .blue
            ) { newPosition in
                onIntent(.moveWorkingAnnotation(toPoint: newPosition))
            }
            .tag(MapFeatureTag.workingAnnotation)
        }
    }
    
    @MapContentBuilder
    private var inProgressPolyline: some MapContent {
        if let workingPolyline = polylineState.workingPolyline, !workingPolyline.coordinates.isEmpty {
            PolylineMapOverlay(
                polyline: workingPolyline,
                strokeColor: polylineState.isTracking ? .purple : .blue
            )
            .tag(MapFeatureTag.workingPolyline)
            
            // Add markers for each point
            ForEach(Array(workingPolyline.coordinates.enumerated()), id: \.1.id) { index, coordinate in
                Annotation(
                    "Point \(index + 1)",
                    coordinate: CLLocationCoordinate2D(coordinate),
                    anchor: .center
                ) {
                    DraggablePolylinePoint(
                        movementEnabled: !workingPolyline.isLocationTracked,
                        fillColor: polylineState.isTracking ? .purple : .blue
                    ) { newPosition in
                        onIntent(.moveWorkingPolyline(pointAtIndex: index, toPoint: newPosition))
                    }
                }
                .tag(MapFeatureTag.workingPolyline)
            }
        }
    }
}
