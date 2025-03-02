import SwiftUI
import struct CoreLocation.CLLocationCoordinate2D

enum PolylineFinalizationError: Error {
    case noCoordinate
    case emptyTitle
    case tooFewCoordinates(required: Int, have: Int)
}

@Observable
class NewPolylineManager {
    private class UndoManager {
        enum Action {
            case move(index: Int, previousCoordinate: Coordinate)
            case append(coordCount: Int)
        }
        
        var actions = [Action]()
    }
    
    var workingPolyline: WorkingPolyline?
    var isShowingOptions = false
    var canUndo: Bool { !undoManager.actions.isEmpty }
    private var undoManager = UndoManager()
    
    func append(_ coordinates: [Coordinate]) {
        if workingPolyline != nil {
            workingPolyline!.coordinates += coordinates
            undoManager.actions.append(.append(coordCount: coordinates.count))
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
    
    func move(index: Int, to coordinate: Coordinate) {
        guard workingPolyline != nil else { return }
        guard index >= 0 && index < workingPolyline!.coordinates.count else { return }
        
        let oldCoordinate = workingPolyline!.coordinates[index]
        workingPolyline?.coordinates[index] = coordinate
        undoManager.actions.append(.move(index: index, previousCoordinate: oldCoordinate))
    }
    
    func move(index: Int, to coordinate: CLLocationCoordinate2D) {
        move(index: index, to: Coordinate(coordinate))
    }
    
    func undo() {
        switch undoManager.actions.popLast() {
        case let .append(coordCount):
            workingPolyline?.coordinates.removeLast(coordCount)
        case let .move(index, previousCoordinate):
            workingPolyline?.coordinates[index] = previousCoordinate
        default:
            break
        }
    }
    
    func clearProgress() {
        isShowingOptions = false
        workingPolyline = nil
        undoManager.actions = []
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
