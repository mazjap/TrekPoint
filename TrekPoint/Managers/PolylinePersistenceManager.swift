import SwiftUI
import SwiftData
import CoreLocation
import Dependencies

enum PolylineFinalizationError: Error {
    case emptyTitle
    case tooFewCoordinates(required: Int, have: Int)
}

enum PolylinePersistenceManagerKey: DependencyKey {
    static let liveValue = PolylinePersistenceManager()
}

extension DependencyValues {
    var polylinePersistenceManager: PolylinePersistenceManager {
        get { self[PolylinePersistenceManagerKey.self] }
        set { self[PolylinePersistenceManagerKey.self] = newValue }
    }
}

@Observable
@MainActor
class PolylinePersistenceManager {
    private class UndoManager {
        enum Action {
            case move(index: Int, previousCoordinate: Coordinate)
            case append(coordCount: Int)
        }
        
        var actions = [Action]()
    }
    
    var workingPolyline: WorkingPolyline?
    
    var isShowingOptions = false
    
    private var undoManager = UndoManager()
    
    @ObservationIgnored @Dependency(\.modelContainer) private var modelContainer
    private var modelContext: ModelContext {
        modelContainer.mainContext
    }
    
    var isDrawingPolyline: Bool { !(workingPolyline?.isLocationTracked ?? true) }
    var isTrackingPolyline: Bool { workingPolyline?.isLocationTracked ?? false }
    var canUndo: Bool { !undoManager.actions.isEmpty }
    
    nonisolated init() {}
    
    /// Clears any existing working polyline data, and starts a new one with the given coordinate
    func startNewWorkingPolyline(with coordinate: Coordinate? = nil) {
        clearWorkingPolylineProgress()
        
        appendWorkingPolylineCoordinate(coordinate)
    }
    
    func startNewLocationTrackedPolyline(withUserCoordinate coordinate: CLLocationCoordinate2D? = nil) {
        clearWorkingPolylineProgress()
        
        appendTrackedPolylineCoordinate(coordinate)
    }
    
    /// Updates the coordinate of the working annotation, or creates a new working annotation if none currently exists
    func appendWorkingPolylineCoordinate(_ coordinate: Coordinate?) {
        if workingPolyline == nil {
            self.workingPolyline = WorkingPolyline(title: "", userDescription: "", coordinates: [], isLocationTracked: false)
        }
        
        guard !workingPolyline!.isLocationTracked else {
            // TODO: - Possible error handling? (an attempt was made to append to a tracked polyline. Not allowed)
            print("Error: Forbidden operation - attempted to append to a tracked polyline. Not allowed.")
            return
        }
        
        if let coordinate {
            workingPolyline!.coordinates.append(coordinate)
            undoManager.actions.append(.append(coordCount: 1))
        }
        
        isShowingOptions = true
    }
    
    func appendTrackedPolylineCoordinate(_ coordinate: CLLocationCoordinate2D?) {
        if workingPolyline == nil {
            workingPolyline = WorkingPolyline(title: "Location Track - \(Date.now, format: Date.FormatStyle(date: .numeric, time: .shortened, locale: .current, calendar: .current, timeZone: .current))", userDescription: "", coordinates: [], isLocationTracked: true)
            isShowingOptions = true
        }
        
        guard workingPolyline!.isLocationTracked else {
            // TODO: - Possible error handling? (an attempt was made to add a user tracked point in a drawn polyline. Not allowed)
            print("Error: Forbidden operation - attempted to add a user-tracked point in a drawn polyline. Not allowed.")
            return
        }
        
        guard let coordinate else { return }
        
        workingPolyline!.coordinates.append(Coordinate(coordinate))
    }
    
    func clearWorkingPolylineProgress() {
        isShowingOptions = false
        workingPolyline = nil
        undoManager.actions = []
    }
    
    func moveWorkingPolylineCoordinate(at index: Int, to coordinate: Coordinate) {
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
    
    func moveWorkingPolylineCoordinate(at index: Int, to coordinate: CLLocationCoordinate2D) {
        moveWorkingPolylineCoordinate(at: index, to: Coordinate(coordinate))
    }
    
    @discardableResult
    func finalizeWorkingPolyline() throws -> PolylineData {
        guard let workingPolyline else { throw PolylineFinalizationError.tooFewCoordinates(required: 2, have: 0) }
        guard !workingPolyline.title.isEmpty else { throw PolylineFinalizationError.emptyTitle }
        guard workingPolyline.coordinates.count > 1 else { throw PolylineFinalizationError.tooFewCoordinates(required: 2, have: workingPolyline.coordinates.count) }
        
        clearWorkingPolylineProgress()
        
        let polylineData = PolylineData(
            title: workingPolyline.title,
            userDescription: workingPolyline.userDescription,
            coordinates: workingPolyline.coordinates,
            isLocationTracked: workingPolyline.isLocationTracked
        )
        
        try savePolyline(polylineData)
        
        return polylineData
    }
    
    func savePolyline(_ polyline: PolylineData) throws {
        if polyline.modelContext == nil {
            modelContext.insert(polyline)
        }
        
        try save()
    }
    
    func deletePolyline(_ polyline: PolylineData) throws {
        modelContext.delete(polyline)
        try save()
    }
    
    // MARK: - General Methods
    
    func save() throws {
        try modelContext.save()
    }
    
    func discardChanges() {
        modelContext.rollback()
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
}
