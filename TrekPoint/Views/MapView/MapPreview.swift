import SwiftUI
import MapboxMaps

struct MapPreview: View {
    private let feature: MapFeature
    
    init(feature: MapFeature) {
        self.feature = feature
    }
    
    private var initialCameraPosition: Viewport {
        switch feature {
        case let .annotation(annotation):
            return .camera(center: annotation.clCoordinate, zoom: 10)
        case let .polyline(polyline):
            let polyline = LineString(polyline.clCoordinates)
            let insets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
            
            return .overview(geometry: Geometry.lineString(polyline), geometryPadding: insets)
        }
    }
    
    @MapContentBuilder
    private var content: some MapContent {
        switch feature {
        case let .annotation(annotation):
            AnnotationMapOverlay(
                annotation: annotation,
                movementEnabled: false,
                foregroundColor: .orange,
                fillColor: type(of: annotation) == AnnotationData.self ? .white : .blue,
                applyNewPosition: {_ in}
            )
        case let .polyline(polyline):
            PolylineMapOverlay(polyline: polyline, strokeColor: polyline.isLocationTracked ? .orange : .red)
        }
    }
    
    var body: some View {
        Map(initialViewport: initialCameraPosition) {
            content
        }
        .mapStyle(.standard) // TODO: - Read from settings
        .gestureOptions(.init(panEnabled: false, pinchEnabled: false, rotateEnabled: false, simultaneousRotateAndPinchZoomEnabled: false, pinchZoomEnabled: false, pinchPanEnabled: false, pitchEnabled: false, doubleTapToZoomInEnabled: false, doubleTouchToZoomOutEnabled: false, quickZoomEnabled: false))
    }
}

#Preview {
    VStack {
        MapPreview(feature: .annotation(AnnotationData(title: "Anakin", coordinate: Coordinate(latitude: 40.05, longitude: -111.67))))
            .frame(width: 150, height: 150)
            .clipShape(.rect(cornerRadius: 20))
        
        MapPreview(feature: .polyline(WorkingPolyline.example))
            .frame(width: 150, height: 150)
            .clipShape(.rect(cornerRadius: 20))
    }
}

