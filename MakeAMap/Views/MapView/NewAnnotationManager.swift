import SwiftUI
import struct CoreLocation.CLLocationCoordinate2D

enum AnnotationFinalizationError: Error {
    case noCoordinate
    case emptyTitle
}

@Observable
class NewAnnotationManager {
    private class UndoManager {
        enum Action {
            case move(previousCoordinate: Coordinate)
        }
        
        var actions = [Action]()
    }
    
    var workingAnnotation: WorkingAnnotation?
    var isShowingOptions = false
    var canUndo: Bool { !undoManager.actions.isEmpty }
    private let undoManager = UndoManager()
    
    func apply(coordinate: Coordinate) {
        if workingAnnotation != nil {
            let oldCoordinate = workingAnnotation!.coordinate
            workingAnnotation!.coordinate = coordinate
            undoManager.actions.append(.move(previousCoordinate: oldCoordinate))
        } else {
            self.workingAnnotation = WorkingAnnotation(coordinate: coordinate, title: "")
        }
        
        isShowingOptions = true
    }
    
    func apply(coordinate: CLLocationCoordinate2D) {
        self.apply(coordinate: Coordinate(coordinate))
    }
    
    func undo() {
        switch undoManager.actions.popLast() {
        case let .move(previousCoordinate):
            workingAnnotation?.coordinate = previousCoordinate
        case .none:
            break
        }
    }
    
    func clearProgress() {
        isShowingOptions = false
        workingAnnotation = nil
        undoManager.actions = []
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
