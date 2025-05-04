@testable import TrekPoint
import Testing
import SwiftData
import UIKit

@MainActor
@Suite
struct AnnotationManagerTests {
    let container: ModelContainer
    let manager: AnnotationPersistenceManager
    
    init() throws {
        self.container = try ModelContainer(for: Schema(versionedSchema: CurrentModelVersion.self), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        self.manager = AnnotationPersistenceManager(modelContainer: container)
    }
    
    func createTestImage() -> UIImage {
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContext(size)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
    @Test("Annotation creation")
    func annotationCreation() throws {
        try #expect(container.mainContext.fetch(FetchDescriptor<AnnotationData>()).count == 0)
        
        let initialCoord = Coordinate(latitude: 40.0, longitude: -111.0)
        manager.changeWorkingAnnotationsCoordinate(to: initialCoord)
        
        #expect(manager.workingAnnotation != nil)
        #expect(manager.workingAnnotation?.coordinate.latitude == 40.0)
        
        manager.workingAnnotation?.title = "Title"
        
        _ = try manager.finalizeWorkingAnnotation()
        
        try #expect(container.mainContext.fetch(FetchDescriptor<AnnotationData>()).count == 1)
    }
    
    @Test("Delete annotation")
    func annotationDeletion() throws {
        manager.changeWorkingAnnotationsCoordinate(to: Coordinate(latitude: 40.0, longitude: -111.0))
        manager.workingAnnotation?.title = "Test Annotation"
        
        let annotation = try manager.finalizeWorkingAnnotation()
        
        try #expect(container.mainContext.fetch(FetchDescriptor<AnnotationData>()).count == 1)
        
        try manager.deleteAnnotation(annotation)
        
        try #expect(container.mainContext.fetch(FetchDescriptor<AnnotationData>()).count == 0)
    }
    
    @Test("Annotation replacement")
    func workingAnnotationReplacement() {
        let initialCoord = Coordinate(latitude: 40.0, longitude: -111.0)
        manager.changeWorkingAnnotationsCoordinate(to: initialCoord)
        manager.workingAnnotation?.title = "Hello, World!"
        
        #expect(manager.workingAnnotation?.coordinate.latitude == 40.0)
        #expect(manager.workingAnnotation?.title == "Hello, World!")
        
        let newCoord = Coordinate(latitude: 41.0, longitude: -112.0)
        manager.startNewWorkingAnnotation(with: newCoord)
        
        #expect(manager.workingAnnotation?.coordinate.latitude == 41.0)
        #expect(manager.workingAnnotation?.title == "", "WorkingAnnotation should have an empty title after being replaced")
    }
    
    @Test("Clear working annotation")
    func clearWorkingAnnotation() {
        manager.startNewWorkingAnnotation(with: .random)
        
        #expect(manager.workingAnnotation != nil)
        #expect(manager.isShowingOptions == true)
        
        manager.clearWorkingAnnotationProgress()
        
        #expect(manager.workingAnnotation == nil)
        #expect(manager.isShowingOptions == false)
    }
    
    @Test("Finalizing annotation without title throws expected error")
    func finalizingWithoutTitleThrowsError() {
        manager.changeWorkingAnnotationsCoordinate(to: Coordinate(latitude: 40, longitude: -111))
        
        do {
            _ = try manager.finalizeWorkingAnnotation()
            #expect(Bool(false), "Should have thrown an error for empty title")
        } catch let error as AnnotationFinalizationError {
            #expect(error == .emptyTitle)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
    
    @Test("Finalizing without a working annotation throws error")
    func noAnnotationThrowsError() {
        manager.clearWorkingAnnotationProgress()
        
        do {
            _ = try manager.finalizeWorkingAnnotation()
            #expect(Bool(false), "Should have thrown an error for no annotation")
        } catch let error as AnnotationFinalizationError {
            #expect(error == .noCoordinate)
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
    
    @Test("Undo coordinate change")
    func undoCoordinateChange() {
        let firstCoord = Coordinate(latitude: 40.0, longitude: -111.0)
        manager.changeWorkingAnnotationsCoordinate(to: firstCoord)
        
        let secondCoord = Coordinate(latitude: 41.0, longitude: -112.0)
        manager.changeWorkingAnnotationsCoordinate(to: secondCoord)
        
        #expect(manager.canUndo == true)
        
        manager.undo()
        
        #expect(manager.workingAnnotation?.coordinate.latitude == 40.0)
        #expect(manager.workingAnnotation?.coordinate.longitude == -111.0)
        #expect(manager.canUndo == false)
    }
    
    @Test("Add and delete attachment")
    func attachmentManagement() throws {
        manager.changeWorkingAnnotationsCoordinate(to: Coordinate(latitude: 40.0, longitude: -111.0))
        manager.workingAnnotation?.title = "Test Annotation"
        
        try manager.addImageToWorkingAnnotation(createTestImage())
        
        #expect(manager.workingAnnotation?.attachments.count == 1)
        
        if let attachment = manager.workingAnnotation?.attachments.first {
            try manager.deleteAttachmentFromWorkingAnnotation(attachment)
            #expect(manager.workingAnnotation?.attachments.count == 0, "Attachment should be deleted")
        } else {
            #expect(Bool(false), "Attachment should exist")
        }
    }
    
    @Test("Properties persist across representations")
    func propertiesRemainTheSameWhenSaving() throws {
        let coordinate = Coordinate(latitude: 40.0, longitude: -110.0)
        let title = "Test"
        let notes = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        
        manager.changeWorkingAnnotationsCoordinate(to: coordinate)
        manager.workingAnnotation?.title = title
        manager.workingAnnotation?.userDescription = notes
        try manager.addImageToWorkingAnnotation(createTestImage())
        
        let annotationData = try manager.finalizeWorkingAnnotation()
        
        #expect(annotationData.coordinate == coordinate)
        #expect(annotationData.title == title)
        #expect(annotationData.userDescription == notes)
        #expect(annotationData.attachments.count == 1)
    }
}
