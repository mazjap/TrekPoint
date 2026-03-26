import SwiftUI
import MapKit

struct AnnotationMapPreview: View {
    private let annotation: any AnnotationProvider
    
    init(annotation: any AnnotationProvider) {
        self.annotation = annotation
    }
    
    private var initialCameraPosition: MapCameraPosition {
        let coordinateSpan = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        let region = MKCoordinateRegion(center: annotation.clCoordinate, span: coordinateSpan)
        
        return .region(region)
    }
    
    var body: some View {
        Map(initialPosition: initialCameraPosition, interactionModes: []) {
            AnnotationMapOverlay(
                annotation: annotation,
                movementEnabled: false,
                foregroundColor: .orange,
                fillColor: type(of: annotation) == AnnotationData.self ? .white : .blue,
                applyNewPosition: {_ in}
            )
        }
    }
}

struct PolylineMapPreview: View {
    private let polyline: any PolylineProvider
    
    init(polyline: any PolylineProvider) {
        self.polyline = polyline
    }
    
    private var initialCameraPosition: MapCameraPosition {
        let boundingBox = MKMapRect(coordinates: polyline.clCoordinates)
        let expandedWidth = boundingBox.width * 1.3
        let widthDelta = expandedWidth - boundingBox.width
        
        let expandedHeight = boundingBox.height * 1.3
        let heightDelta = expandedHeight - boundingBox.height
        
        let origin = MKMapPoint(x: boundingBox.minX - widthDelta / 2, y: boundingBox.minY - heightDelta / 2)
        let size = MKMapSize(width: expandedWidth, height: expandedHeight)
        
        let expandedBox = MKMapRect(origin: origin, size: size)
        
        return .rect(expandedBox)
    }
    
    var body: some View {
        Map(initialPosition: initialCameraPosition, interactionModes: []) {
            PolylineMapOverlay(polyline: polyline, strokeColor: .red)
        }
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

