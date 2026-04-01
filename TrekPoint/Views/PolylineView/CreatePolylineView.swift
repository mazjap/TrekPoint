import SwiftUI
import Dependencies

struct CreatePolylineView: View {
    @Dependency(\.polylinePersistenceManager) private var polylineManager
    private let onDismiss: (Bool) -> Void
    private let onCancel: (PendingSheetCancelAction) -> Void
    private let commitError: (Error) -> Void

    init(onDismiss: @escaping (Bool) -> Void, onCancel: @escaping (PendingSheetCancelAction) -> Void, commitError: @escaping (Error) -> Void) {
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
                        onCancel(.polyline(isTracked: polylineManager.isTrackingPolyline))
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onDismiss(polylineManager.isTrackingPolyline)
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
            onDismiss: { _ in
                
            },
            onCancel: { _ in
                
            },
            commitError: { error in
                print(error)
            }
        )
    }
}
