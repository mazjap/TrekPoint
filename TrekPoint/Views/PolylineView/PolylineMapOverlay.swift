import SwiftUI
import MapboxMaps

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
        PolylineAnnotation(id: polyline.tag.id, lineCoordinates: polyline.clCoordinates, isSelected: false, isDraggable: false)
            .lineColor(UIColor(strokeColor))
            .lineWidth(lineWidth)
            .lineJoin(.round)
            .lineGapWidth(5)
    }
}

#Preview {
    Map {
        PolylineMapOverlay(polyline: WorkingPolyline.example, strokeColor: .red)
    }
}
