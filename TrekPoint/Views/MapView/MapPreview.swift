import SwiftUI
import MapboxMaps

struct AnnotationMapPreview: View {
    private let annotation: any AnnotationProvider
    
    init(annotation: any AnnotationProvider) {
        self.annotation = annotation
    }
    
    private var initialCameraPosition: Viewport {
        return .camera(center: annotation.clCoordinate, zoom: 10)
    }
    
    var body: some View {
        Map(initialViewport: initialCameraPosition) {
            AnnotationMapOverlay(
                annotation: annotation,
                movementEnabled: false,
                categoryColor: type(of: annotation) == AnnotationData.self ? .white : .blue,
                categoryImageName: "star",
                applyNewPosition: {_ in}
            )
        }
        .mapStyle(.standard) // TODO: - Read from settings
        .gestureOptions(.init(panEnabled: false, pinchEnabled: false, rotateEnabled: false, simultaneousRotateAndPinchZoomEnabled: false, pinchZoomEnabled: false, pinchPanEnabled: false, pitchEnabled: false, doubleTapToZoomInEnabled: false, doubleTouchToZoomOutEnabled: false, quickZoomEnabled: false))
    }
}

struct PolylineMapPreview: View {
    private let polyline: any PolylineProvider
    
    init(polyline: any PolylineProvider) {
        self.polyline = polyline
    }
    
    private var initialCameraPosition: Viewport {
        let polyline = LineString(polyline.clCoordinates)
        let insets = EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        
        return .overview(geometry: Geometry.lineString(polyline), geometryPadding: insets)
    }
    
    var body: some View {
        Map(initialViewport: initialCameraPosition) {
            PolylineMapOverlay(polyline: polyline, strokeColor: polyline.isLocationTracked ? .orange : .red)
        }
        .mapStyle(.standard) // TODO: - Read from settings
        .gestureOptions(.init(panEnabled: false, pinchEnabled: false, rotateEnabled: false, simultaneousRotateAndPinchZoomEnabled: false, pinchZoomEnabled: false, pinchPanEnabled: false, pitchEnabled: false, doubleTapToZoomInEnabled: false, doubleTouchToZoomOutEnabled: false, quickZoomEnabled: false))
    }
}

#Preview {
    VStack {
        AnnotationMapPreview(annotation: AnnotationData(title: "Anakin", coordinate: Coordinate(latitude: 40.05, longitude: -111.67)))
            .frame(width: 150, height: 150)
            .clipShape(.rect(cornerRadius: 20))
        
        PolylineMapPreview(polyline: WorkingPolyline.example)
            .frame(width: 150, height: 150)
            .clipShape(.rect(cornerRadius: 20))
    }
}

