import SwiftUI

enum AnnotationFinalizationError: Error {
    case noCoordinate
    case emptyTitle
}

@Observable
class NewAnnotationManager {
    var workingAnnotation: WorkingAnnotation?
    var isShowingOptions = false
    var isEditingDetails = false
    
    var editDetailsBinding: Binding<Bool> {
        Binding {
            self.isEditingDetails && self.workingAnnotation != nil
        } set: {
            self.isEditingDetails = $0
        }
    }
    
    func apply(coordinate: Coordinate) {
        if workingAnnotation != nil {
            workingAnnotation!.coordinate = coordinate
        } else {
            self.workingAnnotation = WorkingAnnotation(coordinate: coordinate, title: "")
        }
        
        isShowingOptions = true
        isEditingDetails = true
    }
    
    func clearProgress() {
        isShowingOptions = false
        isEditingDetails = false
        workingAnnotation = nil
    }
    
    func finalize() throws -> AnnotationData {
        guard let workingAnnotation else { throw AnnotationFinalizationError.noCoordinate }
        guard !workingAnnotation.title.isEmpty else { throw AnnotationFinalizationError.emptyTitle }
        
        clearProgress()
        
        return AnnotationData(
            title: workingAnnotation.title,
            coordinate: workingAnnotation.clCoordinate
        )
    }
}

import CoreLocation.CLLocation

extension NewAnnotationManager {
    func apply(coordinate: CLLocationCoordinate2D) {
        self.apply(coordinate: Coordinate(coordinate))
    }
}
