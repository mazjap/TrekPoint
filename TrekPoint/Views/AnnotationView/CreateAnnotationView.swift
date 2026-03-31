import SwiftUI
import SwiftData
import struct CoreLocation.CLLocationCoordinate2D
import Dependencies

fileprivate enum NavigationState {
    case viewing, creating, canceling
}

struct CreateAnnotationView: View {
    @Dependency(\.annotationPersistenceManager) private var annotationManager
    private let onDismiss: () -> Void
    private let onCancel: () -> Void
    private let commitError: (Error) -> Void

    init(onDismiss: @escaping () -> Void, onCancel: @escaping (PendingSheetCancelAction) -> Void, commitError: @escaping (Error) -> Void) {
        self.onDismiss = onDismiss
        self.onCancel = { onCancel(.annotation) }
        self.commitError = commitError
    }

    var body: some View {
        AnnotationDetailView(annotation: Bindable(annotationManager).workingAnnotation.safelyUnwrapped(WorkingAnnotation(coordinate: .random, title: "")))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        do {
                            try annotationManager.finalizeWorkingAnnotation()
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
    withDependencies { dependencies in
        dependencies.annotationPersistenceManager.changeWorkingAnnotationsCoordinate(to: Coordinate.random)
    } operation: {
        CreateAnnotationView(
            onDismiss: {
                
            }, onCancel: { _ in 
                
            }, commitError: { error in
                print(error)
            }
        )
    }
}
