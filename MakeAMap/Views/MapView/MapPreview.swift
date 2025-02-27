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
            var maxLat: Double = -90
            var minLat: Double = 90
            var maxLng: Double = -180
            var minLng: Double = 180
            
            for point in polyline.coordinates {
                if point.latitude > maxLat {
                    maxLat = point.latitude
                }
                if point.latitude < minLat {
                    minLat = point.latitude
                }
                
                if point.longitude > maxLat {
                    maxLng = point.longitude
                }
                if point.longitude < minLat {
                    minLng = point.longitude
                }
            }
            
            let boundingBox = MKMapRect(
                origin: MKMapPoint(
                x: (maxLat + minLat) / 2,
                y: (maxLng + minLng) / 2),
                size: MKMapSize(width: maxLat - minLat, height: maxLng - minLng)
            )
            
            return .rect(boundingBox)
        }
    }
    
    @MapContentBuilder
    private var content: some MapContent {
        switch feature {
        case let .annotation(annotation):
            Annotation(coordinate: CLLocationCoordinate2D(annotation.coordinate)) {
                DraggablePin(movementEnabled: false, applyNewPosition: {_ in})
                    .foregroundStyle(.red, .blue)
            } label: {
                Text(annotation.title)
            }
            .tag(annotation.id)
        case let .polyline(polyline):
            MapPolyline(
                coordinates: polyline.clCoordinates,
                contourStyle: .geodesic
            )
            .stroke(.red, lineWidth: 5)
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
        
        MapPreview(feature: .polyline(PolylineData.example))
            .frame(width: 150, height: 150)
            .clipShape(.rect(cornerRadius: 20))
    }
}

