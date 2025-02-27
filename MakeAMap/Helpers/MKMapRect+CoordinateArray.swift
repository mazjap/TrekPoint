import MapKit

extension MKMapRect {
    init(coordinates: [CLLocationCoordinate2D]) {
        let mapRect = coordinates.reduce(MKMapRect.null) { rect, coordinate in
            let mapPoint = MKMapPoint(coordinate)
            let pointRect = MKMapRect(x: mapPoint.x, y: mapPoint.y, width: 0, height: 0)
            
            return rect.union(pointRect)
        }
        
        self.init(origin: mapRect.origin, size: mapRect.size)
    }
    
    var center: MKMapPoint {
        MKMapPoint(x: midX, y: midY)
    }
}
