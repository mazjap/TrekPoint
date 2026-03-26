import SwiftUI
import MapboxMaps
import Dependencies

struct GroupedMapContent: MapContent {
    private let annotationState: AnnotationOverlayState
    private let polylineState: PolylineOverlayState
    private let locationState: LocationOverlayState
    private let selection: ResolvedMapFeature?
    private let annotationFeatureCollection: FeatureCollection?
    private let polylineFeatureCollection: FeatureCollection?
    private let onIntent: (GroupedMapContentIntent) -> Void
    private let onSelection: (MapFeatureTag) -> Bool
    
    init(annotationState: AnnotationOverlayState, polylineState: PolylineOverlayState, locationState: LocationOverlayState, selection: ResolvedMapFeature?, annotationFeatureCollection: FeatureCollection?, polylineFeatureCollection: FeatureCollection?, onIntent: @escaping (GroupedMapContentIntent) -> Void, onSelection: @escaping (MapFeatureTag) -> Bool) {
        self.annotationState = annotationState
        self.polylineState = polylineState
        self.locationState = locationState
        self.selection = selection
        self.annotationFeatureCollection = annotationFeatureCollection
        self.polylineFeatureCollection = polylineFeatureCollection
        self.onIntent = onIntent
        self.onSelection = onSelection
    }
    
    var body: some MapContent {
        if let annotationFeatureCollection {
            GeoJSONSource(id: "annotation-source")
                .data(.featureCollection(annotationFeatureCollection))
        }
        
        if let polylineFeatureCollection {
            GeoJSONSource(id: "polyline-source")
                .data(.featureCollection(polylineFeatureCollection))
        }
        
        if locationState.isActive {
            Puck2D(bearing: .heading)
        }
        
        annotationViews
        
        polylineViews
        
        inProgressPolyline
        
        inProgressPin
    }
    
    @MapContentBuilder
    private var annotationViews: some MapContent {
        // TODO: - Clustering
        SymbolLayer(id: "marker-layer", source: "annotation-source")
            .iconImage("marker")
            .textFont(["Open Sans Bold"])
            .iconAnchor(.bottom)
            .textSize(12)
            .textColor(.white)
            .textAnchor(.top)
            .textHaloWidth(2)
            .textHaloColor(.black)
            .textHaloBlur(1)
            .textOffset(x: 0, y: 0.25)
            .iconAllowOverlap(true)
            .textOptional(true)
            .textField(Exp(.get) { "title" })
        
        TapInteraction(.layer("marker-layer")) { feature, context in
            guard let id = feature.id?.id,
                  let tag = MapFeatureTag(rawValue: id)
            else {
                return false
            }
            
            return onSelection(tag)
        }
        
        if case let .annotation(annotation) = selection {
            AnnotationMapOverlay(annotation: annotation, movementEnabled: true, shouldJiggle: false, categoryImageName: "star") { newPosition in
                onIntent(.moveAnnotation(annotation: annotation, toPoint: newPosition))
            }
        }
    }
    
    @MapContentBuilder
    private var polylineViews: some MapContent {
        LineLayer(id: "line-layer", source: "polyline-source")
            .lineWidth(5)
            .lineJoin(.round)
            .lineDashArray([3, 2])
            .lineColor(Exp(.switchCase) {
                Exp(.boolean) { Exp(.get) { "isLocationTracked" } }
                Exp(.toColor) { "#FF8D28" }
                Exp(.toColor) { "#FE383C" }
            })
        
        // TODO: - Look into laying out text on top of path
        
        TapInteraction(.layer("line-layer")) { feature, context in
            guard let id = feature.id?.id,
                  let tag = MapFeatureTag(rawValue: id)
            else {
                return false
            }
            
            return onSelection(tag)
        }
    }
    
    @MapContentBuilder
    private var inProgressPin: some MapContent {
        if let newAnnotationLocation = annotationState.workingAnnotation {
            AnnotationMapOverlay(
                annotation: newAnnotationLocation,
                shouldJiggle: annotationState.isShowingOptions,
                categoryColor: .blue,
                categoryImageName: "star"
            ) { newPosition in
                onIntent(.moveWorkingAnnotation(toPoint: newPosition))
            }
        }
    }
    
    @MapContentBuilder
    private var inProgressPolyline: some MapContent {
        if let workingPolyline = polylineState.workingPolyline, !workingPolyline.coordinates.isEmpty {
            PolylineAnnotation(id: workingPolyline.tag.id, lineCoordinates: workingPolyline.clCoordinates, isSelected: false, isDraggable: false)
                .lineColor(UIColor(polylineState.isTracking ? .purple : .blue))
                .lineWidth(3)
                .lineJoin(.round)
            
            // Add markers for each point
            ForEvery(Array(workingPolyline.coordinates.enumerated()), id: \.1.id) { index, coordinate in
                MapViewAnnotation(coordinate: CLLocationCoordinate2D(coordinate)) {
                    DraggablePolylinePoint(
                        movementEnabled: !workingPolyline.isLocationTracked,
                        fillColor: polylineState.isTracking ? .purple : .blue
                    ) { newPosition in
                        onIntent(.moveWorkingPolyline(pointAtIndex: index, toPoint: newPosition))
                    }
                }
            }
        }
    }
}
