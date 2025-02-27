import SwiftUI
import MapKit

struct TestMap: View {
    var body: some View {
        Map {
            MapPolyline(coordinates: [
                CLLocationCoordinate2D(latitude: -0.09, longitude: -0.09),
                CLLocationCoordinate2D(latitude: 0, longitude: 0),
                CLLocationCoordinate2D(latitude: 0.09, longitude: 0.09)
            ])
            .stroke(.red, lineWidth: 150)
            
            MapPolyline(coordinates: PolylineData.example.clCoordinates)
            .stroke(.red, lineWidth: 150)
        }
    }
}

#Preview {
    TestMap()
}
