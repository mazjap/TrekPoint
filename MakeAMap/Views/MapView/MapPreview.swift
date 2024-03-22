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
        }
    }
    
    var body: some View {
        Map(initialPosition: initialCameraPosition, interactionModes: []) {
            content
        }
    }
}

#Preview {
    MapPreview(feature: .annotation(AnnotationData(title: "Anakin", coordinate: Coordinate(latitude: 40.05, longitude: -111.67))))
        .frame(width: 150, height: 150)
        .clipShape(.rect(cornerRadius: 20))
}

