import SwiftUI
import struct CoreLocation.CLLocationCoordinate2D

enum PolylineFinalizationError: Error {
    case noCoordinate
    case emptyTitle
    case tooFewCoordinates(required: Int, have: Int)
}

@Observable
class NewPolylineManager {
    var workingPolyline: WorkingPolyline?
    var isShowingOptions = false
    
    func append(_ coordinates: [Coordinate]) {
        if workingPolyline != nil {
            workingPolyline!.coordinates += coordinates
        } else {
            self.workingPolyline = WorkingPolyline(coordinates: coordinates, title: "")
        }
        
        isShowingOptions = true
    }
    
    func append(_ coordinate: Coordinate) {
        append([coordinate])
    }
    
    @_disfavoredOverload
    func append(_ coordinates: [CLLocationCoordinate2D]) {
        self.append(coordinates.map { Coordinate($0) })
    }
    
    @_disfavoredOverload
    func append(_ coordinate: CLLocationCoordinate2D) {
        append([coordinate])
    }
    
    func clearProgress() {
        isShowingOptions = false
        workingPolyline = nil
    }
    
    func finalize() throws -> PolylineData {
        guard let workingPolyline else { throw PolylineFinalizationError.noCoordinate }
        guard !workingPolyline.title.isEmpty else { throw PolylineFinalizationError.emptyTitle }
        guard workingPolyline.coordinates.count > 1 else { throw PolylineFinalizationError.tooFewCoordinates(required: 2, have: workingPolyline.coordinates.count) }
        
        clearProgress()
        
        return PolylineData(
            title: workingPolyline.title,
            coordinates: workingPolyline.coordinates
        )
    }
}

struct AnnotationPoint: AnnotationProvider {
    let index: Int
    let coordinate: Coordinate
    let isLast: Bool
    var title: String { "Point \(index + 1)" }
    var tag: MapFeatureTag { .newFeature }
    var clCoordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(coordinate) }
}
