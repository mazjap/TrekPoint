import SwiftUI
import Dependencies

struct CreatePolylineView: View {
    @Dependency(\.polylinePersistenceManager) private var polylineManager
    private let onDismiss: () -> Void
    private let onCancel: () -> Void
    private let commitError: (Error) -> Void

    init(onDismiss: @escaping () -> Void, onCancel: @escaping () -> Void, commitError: @escaping (Error) -> Void) {
        self.onDismiss = onDismiss
        self.onCancel = onCancel
        self.commitError = commitError
    }

    var body: some View {
        let polylineBinding = Bindable(polylineManager).workingPolyline.safelyUnwrapped(.init(title: "", userDescription: "", coordinates: [], isLocationTracked: false))

        PolylineDetailView(polyline: polylineBinding)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        do {
                            try polylineManager.finalizeWorkingPolyline()
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
        dependencies.polylinePersistenceManager.startNewWorkingPolyline(with: .random)
        dependencies.polylinePersistenceManager.appendWorkingPolylineCoordinate(.random)
    } operation: {
        
        CreatePolylineView(
            onDismiss: {},
            onCancel: {},
            commitError: { error in
                print(error)
            }
        )
    }
}
