import SwiftUI
import Dependencies

struct ModifyAnnotationView: View {
    @Dependency(\.annotationPersistenceManager) private var annotationManager
    @Dependency(\.toastManager) private var toastManager
    private let annotation: AnnotationData
    private let onDismiss: () -> Void
    private let commitError: (Error) -> Void
    
    init(annotation: AnnotationData, onDismiss: @escaping () -> Void, commitError: @escaping (Error) -> Void) {
        self.annotation = annotation
        self.onDismiss = onDismiss
        self.commitError = commitError
    }
    
    var body: some View {
        AnnotationDetailView(annotation: annotation)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        annotationManager.discardChanges()
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            guard !annotation.title.isEmpty else {
                                toastManager.addBreadForToasting(.annotationCreationError(.emptyTitle))
                                return
                            }
                            
                            try annotationManager.save()
                            onDismiss()
                        } catch {
                            commitError(error)
                        }
                    }
                }
            }
    }
}

#Preview {
    ModifyAnnotationView(annotation: AnnotationData(title: WorkingAnnotation.example.title, coordinate: WorkingAnnotation.example.coordinate), onDismiss: {}) { print($0) }
}
