import SwiftData
import Foundation
import struct CoreLocation.CLLocationCoordinate2D
import class UIKit.UIImage

enum AnnotationFinalizationError: Error {
    case noCoordinate
    case emptyTitle
    case noAnnotation
}

@Observable
@MainActor
class AnnotationPersistenceManager {
    private class UndoManager {
        enum Action {
            case move(previousCoordinate: Coordinate)
        }
        
        var actions = [Action]()
    }
    
    var workingAnnotation: WorkingAnnotation?
    var isShowingOptions = false
    
    private let undoManager: UndoManager
    private let modelContainer: ModelContainer
    private var modelContext: ModelContext
    private let attachmentStore: AttachmentProvider
    
    var canUndo: Bool { !undoManager.actions.isEmpty }
    
    init(modelContainer: ModelContainer, attachmentStore: AttachmentProvider) {
        self.undoManager = UndoManager()
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
        self.attachmentStore = attachmentStore
    }
    
    // MARK: - Attachment Methods
    
    func addImage(_ image: UIImage, to annotation: AnnotationData) throws {
        let attachment = try attachmentStore.storeImage(image)
        
        try addAttachment(attachment, to: annotation)
    }
    
    func addVideo(thatExistsAtURL url: URL, to annotation: AnnotationData) throws {
        let attachment = try attachmentStore.storeVideo(thatExistsAtURL: url)
        
        try addAttachment(attachment, to: annotation)
    }
    
    func delete(_ attachment: Attachment, from annotation: AnnotationData) throws {
        try attachmentStore.delete(attachment)
        
        guard let index = annotation.attachments.firstIndex(where: { $0.id == attachment.id }) else { return }
        try deleteAttachment(at: index, from: annotation)
    }
    
    func deleteAttachment(at index: Int, from annotation: AnnotationData) throws {
        try attachmentStore.delete(annotation.attachments[index])
        
        annotation.attachments.remove(at: index)
        try save()
    }
    
    func addImageToWorkingAnnotation(_ image: UIImage) throws {
        guard workingAnnotation != nil else { throw AnnotationFinalizationError.noAnnotation }
        
        workingAnnotation!.attachments.append(try attachmentStore.storeImage(image))
    }
    
    func addVideoToWorkingAnnotation(thatExistsAtURL url: URL) throws {
        guard workingAnnotation != nil else { throw AnnotationFinalizationError.noAnnotation }
        
        workingAnnotation!.attachments.append(try attachmentStore.storeVideo(thatExistsAtURL: url))
    }
    
    func deleteAttachmentFromWorkingAnnotation(_ attachment: Attachment) throws {
        guard workingAnnotation != nil else { throw AnnotationFinalizationError.noAnnotation }
        guard let index = workingAnnotation?.attachments.firstIndex(where: { $0.id == attachment.id }) else { return }
        
        try deleteAttachmentFromWorkingAnnotation(at: index)
    }
    
    func deleteAttachmentFromWorkingAnnotation(at index: Int) throws {
        guard workingAnnotation != nil else { throw AnnotationFinalizationError.noAnnotation }
        
        try attachmentStore.delete(workingAnnotation!.attachments[index])
        workingAnnotation?.attachments.remove(at: index)
    }
    
    func getUrl(for attachment: Attachment) throws -> URL {
        try attachmentStore.getUrl(for: attachment)
    }
    
    func attachmentExists(_ attachment: Attachment) -> Bool {
        attachmentStore.exists(attachment)
    }
    
    // MARK: - Annotation Methods
    
    /// Clears any existing working annotation data, and starts a new one with the given coordinate
    func startNewWorkingAnnotation(with coordinate: Coordinate) {
        if let workingAnnotation {
            for attachment in workingAnnotation.attachments {
                try! deleteAttachmentFromWorkingAnnotation(attachment)
            }
        }
        
        clearWorkingAnnotationProgress()
        changeWorkingAnnotationsCoordinate(to: coordinate)
    }
    
    /// Updates the coordinate of the working annotation, or creates a new working annotation if none currently exists
    func changeWorkingAnnotationsCoordinate(to coordinate: Coordinate) {
        if workingAnnotation != nil {
            let oldCoordinate = workingAnnotation!.coordinate
            workingAnnotation!.coordinate = coordinate
            undoManager.actions.append(.move(previousCoordinate: oldCoordinate))
        } else {
            self.workingAnnotation = WorkingAnnotation(coordinate: coordinate, title: "")
        }
        
        isShowingOptions = true
    }
    
    func clearWorkingAnnotationProgress() {
        _clearWorkingAnnotationProgress(removeAttachments: true)
    }
    
    private func _clearWorkingAnnotationProgress(removeAttachments: Bool) {
        isShowingOptions = false
        
        if removeAttachments, let attachments = workingAnnotation?.attachments {
            for attachment in attachments {
                do {
                    try deleteAttachmentFromWorkingAnnotation(attachment)
                } catch {
                    // TODO: - Gracefully handle error (toast?) instead of swallowing
                    print(error)
                }
            }
        }
        
        workingAnnotation = nil
        undoManager.actions = []
    }
    
    @discardableResult
    func finalizeWorkingAnnotation() throws -> AnnotationData {
        guard let workingAnnotation else { throw AnnotationFinalizationError.noCoordinate }
        guard !workingAnnotation.title.isEmpty else { throw AnnotationFinalizationError.emptyTitle }
        
        _clearWorkingAnnotationProgress(removeAttachments: false)
        
        let annotationData = AnnotationData(
            title: workingAnnotation.title,
            userDescription: workingAnnotation.userDescription,
            coordinate: workingAnnotation.coordinate,
            attachments: workingAnnotation.attachments
        )
        
        try saveAnnotation(annotationData)
        
        return annotationData
    }
    
    func saveAnnotation(_ annotation: AnnotationData) throws {
        if annotation.modelContext == nil {
            modelContext.insert(annotation)
        }
        
        try save()
    }
    
    func deleteAnnotation(_ annotation: AnnotationData) throws {
        modelContext.delete(annotation)
        try save()
    }
    
    func addAttachment(_ attachment: Attachment, to annotation: AnnotationData) throws {
        annotation.attachments.append(attachment)
        try save()
    }
    
    func save() throws {
        try modelContext.save()
    }
    
    func discardChanges() {
        modelContext.rollback()
    }
    
    func undo() {
        switch undoManager.actions.popLast() {
        case let .move(previousCoordinate):
            workingAnnotation?.coordinate = previousCoordinate
        case .none:
            break
        }
    }
}
