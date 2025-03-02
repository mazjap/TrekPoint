import SwiftUI
import MapKit

struct PolylineMapOverlay: MapContent {
    let polyline: any PolylineProvider
    let strokeColor: Color
    let lineWidth: CGFloat
    let dashPattern: [CGFloat]?
    
    init(
        polyline: any PolylineProvider,
        strokeColor: Color,
        lineWidth: CGFloat = 3,
        dashPattern: [CGFloat]? = [5, 8]
    ) {
        self.polyline = polyline
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
        self.dashPattern = dashPattern
    }
    
    var body: some MapContent {
        MapPolyline(coordinates: polyline.clCoordinates)
            .stroke(strokeColor, style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round,
                miterLimit: 5,
                dash: dashPattern ?? []
            ))
            .tag(polyline.tag)
    }
}

#Preview {
    Map {
        PolylineMapOverlay(polyline: WorkingPolyline.example, strokeColor: .red)
    }
}
