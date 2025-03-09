import SwiftUI
import MapKit

struct MapPreview: View {
    private let feature: MapFeature
    
    init(feature: MapFeature) {
        self.feature = feature
    }
    
    private var initialCameraPosition: MapCameraPosition {
        switch feature {
        case let .annotation(annotation):
            let coordinateSpan = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
            let region = MKCoordinateRegion(center: annotation.clCoordinate, span: coordinateSpan)
            
            return .region(region)
        case let .polyline(polyline):
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
            PolylineMapOverlay(polyline: polyline, strokeColor: .red)
        }
    }
    
    var body: some View {
        Map(initialPosition: initialCameraPosition, interactionModes: []) {
            content
        }
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

