import SwiftUI
import SwiftData
import struct CoreLocation.CLLocationCoordinate2D
import Dependencies

fileprivate enum NavigationState {
    case viewing, creating, canceling
}

struct CreateAnnotationView: View {
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.annotationPersistenceManager) private var annotationManager
    @State private var showCancelConfirmation = false
    private let onDismiss: () -> Void
    private let commitError: (Error) -> Void

    init(onDismiss: @escaping () -> Void, commitError: @escaping (Error) -> Void) {
        self.onDismiss = onDismiss
        self.commitError = commitError
    }

    var body: some View {
        AnnotationDetailView(annotation: Bindable(annotationManager).workingAnnotation.safelyUnwrapped(WorkingAnnotation(coordinate: .random, title: "")))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCancelConfirmation = true
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        do {
                            try annotationManager.finalizeWorkingAnnotation()
                        } catch {
                            commitError(error)
                        }
                    }
                }
            }
            .onChange(of: annotationManager.workingAnnotation) {
                if annotationManager.workingAnnotation == nil {
                    onDismiss()
                    dismiss()
                }
            }
            .confirmationDialog(
                "Discard Annotation?",
                isPresented: $showCancelConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) {
                    annotationManager.clearWorkingAnnotationProgress()
                }
            } message: {
                Text("Your in-progress annotation will be discarded.")
            }
    }
}

#Preview {
    withDependencies { dependencies in
        dependencies.annotationPersistenceManager.changeWorkingAnnotationsCoordinate(to: Coordinate.random)
    } operation: {
        CreateAnnotationView(onDismiss: {}) { print($0) }
    }
}
