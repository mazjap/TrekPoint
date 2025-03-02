import SwiftUI
import struct CoreLocation.CLLocationCoordinate2D

enum AnnotationFinalizationError: Error {
    case noCoordinate
    case emptyTitle
}

@Observable
class NewAnnotationManager {
    var workingAnnotation: WorkingAnnotation?
    var isShowingOptions = false
    
    func apply(coordinate: Coordinate) {
        if workingAnnotation != nil {
            workingAnnotation!.coordinate = coordinate
        } else {
            self.workingAnnotation = WorkingAnnotation(coordinate: coordinate, title: "")
        }
        
        isShowingOptions = true
    }
    
    func apply(coordinate: CLLocationCoordinate2D) {
        self.apply(coordinate: Coordinate(coordinate))
    }
    
    func clearProgress() {
        isShowingOptions = false
        workingAnnotation = nil
    }
    
    func finalize() throws -> AnnotationData {
        guard let workingAnnotation else { throw AnnotationFinalizationError.noCoordinate }
        guard !workingAnnotation.title.isEmpty else { throw AnnotationFinalizationError.emptyTitle }
        
        clearProgress()
        
        return AnnotationData(
            title: workingAnnotation.title,
            coordinate: workingAnnotation.coordinate
        )
    }
}
