import SwiftUI
import MapKit

struct PolylineMapOverlay: MapContent {
    let polyline: any PolylineProvider
    let strokeColor: Color
    
    var body: some MapContent {
        MapPolyline(coordinates: polyline.clCoordinates)
            .stroke(strokeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, miterLimit: 5, dash: [5, 8]))
            .tag(polyline.tag)
    }
}

#Preview {
    Map {
        PolylineMapOverlay(polyline: WorkingPolyline.example, strokeColor: .red)
    }
}
