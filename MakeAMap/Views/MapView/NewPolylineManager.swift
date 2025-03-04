import SwiftUI
import CoreLocation

enum PolylineFinalizationError: Error {
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
    var isDrawingPolyline: Bool { !(workingPolyline?.isLocationTracked ?? true) }
    var isTrackingPolyline: Bool { workingPolyline?.isLocationTracked ?? false }
    var canUndo: Bool { !undoManager.actions.isEmpty }
    private var undoManager = UndoManager()
    
    func append(_ coordinates: [Coordinate]) {
        if workingPolyline == nil {
            self.workingPolyline = WorkingPolyline(title: "", userDescription: "", coordinates: coordinates, isLocationTracked: false)
        } else if !workingPolyline!.isLocationTracked {
            workingPolyline!.coordinates += coordinates
            undoManager.actions.append(.append(coordCount: coordinates.count))
        } else {
            // TODO: - Possible error handling? (an attempt was made to append to a tracked polyline. Not allowed)
            print("Error: Forbidden operation - attempted to append to a tracked polyline. Not allowed.")
            return
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
        guard !workingPolyline!.isLocationTracked else {
            // TODO: - Possible error handling? (an attempt was made to move a point in a tracked polyline. Not allowed)
            print("Error: Forbidden operation - attempted to move a point in a tracked polyline. Not allowed.")
            return
        }
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
    
    func startLocationTracking(currentLocation: CLLocationCoordinate2D?) {
        workingPolyline = WorkingPolyline(title: "Location Track - \(Date.now, format: Date.FormatStyle(date: .numeric, time: .shortened, locale: .current, calendar: .current, timeZone: .current))", userDescription: "", coordinates: [], isLocationTracked: true)
        isShowingOptions = true
        
        if let currentLocation {
            appendCurrentLocation(currentLocation)
        }
    }
    
    func appendCurrentLocation(_ coordinate: CLLocationCoordinate2D) {
        guard workingPolyline != nil else { return }
        guard workingPolyline!.isLocationTracked else {
            // TODO: - Possible error handling? (an attempt was made to add a user tracked point in a drawn polyline. Not allowed)
            print("Error: Forbidden operation - attempted to add a user-tracked point in a drawn polyline. Not allowed.")
            return
        }
        
        // Only add if significantly different from last point
        if let lastCoord = workingPolyline?.coordinates.last {
            let lastCLCoord = CLLocationCoordinate2D(lastCoord)
            let distance = locationDistance(lastCLCoord, coordinate)
            
            if distance > 5.0 {
                workingPolyline!.coordinates.append(Coordinate(coordinate))
            }
        } else {
            workingPolyline!.coordinates.append(Coordinate(coordinate))
        }
    }
    
    func clearProgress() {
        isShowingOptions = false
        workingPolyline = nil
        undoManager.actions = []
    }
    
    func finalize() throws -> PolylineData {
        guard let workingPolyline else { throw PolylineFinalizationError.tooFewCoordinates(required: 2, have: 0) }
        guard !workingPolyline.title.isEmpty else { throw PolylineFinalizationError.emptyTitle }
        guard workingPolyline.coordinates.count > 1 else { throw PolylineFinalizationError.tooFewCoordinates(required: 2, have: workingPolyline.coordinates.count) }
        
        clearProgress()
        
        return PolylineData(
            title: workingPolyline.title,
            userDescription: workingPolyline.userDescription,
            coordinates: workingPolyline.coordinates,
            isLocationTracked: workingPolyline.isLocationTracked
        )
    }
    
    /// Returns the distance (in meters) from `coord1` to `coord2`
    private func locationDistance(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let loc2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return loc1.distance(from: loc2)
    }
}
