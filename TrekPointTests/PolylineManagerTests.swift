@testable import TrekPoint
import Testing
import SwiftData
import CoreLocation

@MainActor
@Suite
struct PolylineManagerTests {
    let container: ModelContainer
    let manager: PolylinePersistenceManager
    
    init() throws {
        self.container = try ModelContainer(for: Schema(versionedSchema: CurrentModelVersion.self), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        self.manager = PolylinePersistenceManager(modelContainer: container)
    }
    
    @Test("Drawn polyline creation")
    func polylineCreation() throws {
        try #expect(container.mainContext.fetch(FetchDescriptor<PolylineData>()).count == 0)
        
        let coords = [Coordinate(latitude: 40.0, longitude: -111.0), Coordinate(latitude: 41.0, longitude: -111.0)]
        
        for coord in coords {
            manager.appendWorkingPolylineCoordinate(coord)
        }
        
        #expect(manager.workingPolyline != nil)
        #expect(manager.workingPolyline?.coordinates == coords)
        #expect(manager.workingPolyline?.isLocationTracked == false)
        
        manager.workingPolyline?.title = "Title"
        
        _ = try manager.finalizeWorkingPolyline()
        
        try #expect(container.mainContext.fetch(FetchDescriptor<PolylineData>()).count == 1)
    }
    
    @Test("Location tracked polyline creation")
    func locationTrackedPolylineCreation() throws {
        try #expect(container.mainContext.fetch(FetchDescriptor<PolylineData>()).count == 0)
        
        let coords = [CLLocationCoordinate2D(latitude: 40.0, longitude: -111.0), CLLocationCoordinate2D(latitude: 40.01, longitude: -111.01)]
        
        for coord in coords {
            manager.appendTrackedPolylineCoordinate(coord)
        }
        
        #expect(manager.workingPolyline != nil)
        #expect(manager.workingPolyline?.coordinates.map { CLLocationCoordinate2D($0) } == coords)
        #expect(manager.workingPolyline?.isLocationTracked == true)
        
        #expect(!manager.workingPolyline!.title.isEmpty)
        #expect(manager.workingPolyline!.title.contains("Location Track"))
        
        let polylineData = try manager.finalizeWorkingPolyline()
        
        #expect(polylineData.isLocationTracked == true)
        try #expect(container.mainContext.fetch(FetchDescriptor<PolylineData>()).count == 1)
    }
    
    @Test("Delete polyline")
    func polylineDeletion() throws {
        let coords = [Coordinate(latitude: 40.0, longitude: -111.0), Coordinate(latitude: 41.0, longitude: -111.0)]
        
        for coord in coords {
            manager.appendWorkingPolylineCoordinate(coord)
        }
        
        manager.workingPolyline?.title = "Test Polyline"
        
        let polyline = try manager.finalizeWorkingPolyline()
        
        try #expect(container.mainContext.fetch(FetchDescriptor<PolylineData>()).count == 1)
        
        try manager.deletePolyline(polyline)
        
        try #expect(container.mainContext.fetch(FetchDescriptor<PolylineData>()).count == 0)
    }
    
    @Test("Polyline replacement")
    func workingPolylineReplacement() {
        let initialCoord = Coordinate(latitude: 40.0, longitude: -111.0)
        manager.appendWorkingPolylineCoordinate(initialCoord)
        manager.workingPolyline?.title = "Hello, World!"
        
        #expect(manager.workingPolyline?.coordinates.count == 1)
        #expect(manager.workingPolyline?.coordinates.first?.latitude == 40.0)
        #expect(manager.workingPolyline?.title == "Hello, World!")
        
        manager.startNewWorkingPolyline()
        
        #expect(manager.workingPolyline?.coordinates.count == 0)
        #expect(manager.workingPolyline?.title == "", "WorkingPolyline should have an empty title after being replaced")
    }
    
    @Test("Clear working polyline")
    func clearWorkingPolyline() {
        manager.startNewWorkingPolyline(with: .random)
        
        #expect(manager.workingPolyline != nil)
        #expect(manager.isShowingOptions == true)
        
        manager.clearWorkingPolylineProgress()
        
        #expect(manager.workingPolyline == nil)
        #expect(manager.isShowingOptions == false)
    }
    
    @Test("Finalizing polyline without title throws expected error")
    func finalizingWithoutTitleThrowsError() {
        manager.appendWorkingPolylineCoordinate(Coordinate(latitude: 40.0, longitude: -111.0))
        
        do {
            _ = try manager.finalizeWorkingPolyline()
            #expect(Bool(false), "Should have thrown an error for empty title")
        } catch PolylineFinalizationError.emptyTitle {
            // All good here
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
    
    @Test("Finalizing without a working polyline throws error")
    func noPolylineThrowsError() {
        manager.clearWorkingPolylineProgress()
        
        do {
            _ = try manager.finalizeWorkingPolyline()
            #expect(Bool(false), "Should have thrown an error for no polyline")
        } catch PolylineFinalizationError.tooFewCoordinates, PolylineFinalizationError.emptyTitle {
            // All good here
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
    
    @Test("Finalizing polyline with too few coordinates throws error")
    func finalizingWithTooFewCoordinatesThrowsError() {
        manager.startNewWorkingPolyline()
        manager.appendWorkingPolylineCoordinate(Coordinate(latitude: 40.0, longitude: -111.0))
        manager.workingPolyline?.title = "Test Polyline"
        
        do {
            _ = try manager.finalizeWorkingPolyline()
            #expect(Bool(false), "Should have thrown an error for too few coordinates")
        } catch PolylineFinalizationError.tooFewCoordinates(let needed, let have) {
            #expect(needed == 2)
            #expect(have == 1)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
    
    @Test("Undo coordinate change")
    func undoCoordinateChange() {
        let firstCoord = Coordinate(latitude: 40.0, longitude: -111.0)
        manager.appendWorkingPolylineCoordinate(firstCoord)
        
        let secondCoord = Coordinate(latitude: 41.0, longitude: -112.0)
        manager.appendWorkingPolylineCoordinate(secondCoord)
        
        #expect(manager.workingPolyline?.coordinates.last == secondCoord)
        #expect(manager.canUndo == true)
        
        manager.undo()
        
        #expect(manager.workingPolyline?.coordinates.last == firstCoord)
        #expect(manager.canUndo == true)
        
        manager.undo()
        
        #expect(manager.workingPolyline?.coordinates.isEmpty ?? false)
        #expect(manager.canUndo == false)
    }
    
    @Test("Properties persist across representations")
    func propertiesRemainTheSameWhenSaving() throws {
        let coordinates = [Coordinate(latitude: 40.0, longitude: -110.0), Coordinate(latitude: 41.0, longitude: -111.0)]
        let title = "Test"
        let notes = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        
        for coordinate in coordinates {
            manager.appendWorkingPolylineCoordinate(coordinate)
        }
        
        manager.workingPolyline?.title = title
        manager.workingPolyline?.userDescription = notes
        
        let polylineData = try manager.finalizeWorkingPolyline()
        
        #expect(polylineData.coordinates == coordinates)
        #expect(polylineData.title == title)
        #expect(polylineData.userDescription == notes)
    }

    @Test("Cannot move coordinates in tracked polyline")
    func cannotMoveCoordinatesInTrackedPolyline() {
        manager.startNewLocationTrackedPolyline()
        manager.appendTrackedPolylineCoordinate(CLLocationCoordinate2D(latitude: 40.0, longitude: -111.0))
        
        let newCoord = Coordinate(latitude: 45.0, longitude: -115.0)
        
        // TODO: Throw an error here instead of swallowing
        manager.moveWorkingPolylineCoordinate(at: 0, to: newCoord) // Should be ignored
        
        #expect(manager.workingPolyline?.coordinates[0].latitude == 40.0)
        #expect(manager.workingPolyline?.coordinates[0].longitude == -111.0)
    }

    @Test("Cannot add coordinates to tracked polyline using non-tracked method")
    func cannotAddCoordinatesNormallyToTrackedPolyline() {
        manager.startNewLocationTrackedPolyline()
        manager.appendTrackedPolylineCoordinate(CLLocationCoordinate2D(latitude: 40.0, longitude: -111.0))
        
        // TODO: Throw an error here instead of swallowing
        manager.appendWorkingPolylineCoordinate(Coordinate(latitude: 41.0, longitude: -112.0)) // Should be ignored
        
        #expect(manager.workingPolyline?.coordinates.count == 1)
    }

    @Test("Tracked and drawn polylines can be distinguished")
    func canDifferentiatePolylineTypes() {
        manager.startNewWorkingPolyline()
        #expect(manager.isDrawingPolyline == true)
        #expect(manager.isTrackingPolyline == false)
        
        manager.clearWorkingPolylineProgress()
        
        manager.startNewLocationTrackedPolyline()
        #expect(manager.isDrawingPolyline == false)
        #expect(manager.isTrackingPolyline == true)
    }
}
