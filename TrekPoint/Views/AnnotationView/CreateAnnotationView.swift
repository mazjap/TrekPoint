import SwiftUI
import SwiftData
import struct CoreLocation.CLLocationCoordinate2D

fileprivate enum NavigationState {
    case viewing, creating, canceling
}

struct CreateAnnotationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AnnotationPersistenceManager.self) private var annotationManager
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
                        annotationManager.clearWorkingAnnotationProgress()
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
    }
}

#Preview {
    let newAnnotationManager = {
        let annotationManager = AnnotationPersistenceManager(modelContainer: .preview)
        annotationManager.changeWorkingAnnotationsCoordinate(to: Coordinate.random)
        return annotationManager
    }()
    
    CreateAnnotationView(onDismiss: {}) { print($0) }
        .environment(newAnnotationManager)
}
