import SwiftUI

struct ModifyAnnotationView: View {
    @Environment(AnnotationPersistenceManager.self) private var annotationManager
    @Environment(\.dismiss) private var dismiss
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
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try annotationManager.save()
                            onDismiss()
                            dismiss()
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
        .environment(AnnotationPersistenceManager(modelContainer: .preview))
}
