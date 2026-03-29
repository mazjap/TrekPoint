import SwiftUI
import Dependencies

struct CreatePolylineView: View {
    @Environment(\.dismiss) private var dismiss
    @Dependency(\.polylinePersistenceManager) private var polylineManager
    @State private var showCancelConfirmation = false
    private let onDismiss: () -> Void
    private let commitError: (Error) -> Void

    init(onDismiss: @escaping () -> Void, commitError: @escaping (Error) -> Void) {
        self.onDismiss = onDismiss
        self.commitError = commitError
    }

    var body: some View {
        let polylineBinding = Bindable(polylineManager).workingPolyline.safelyUnwrapped(.init(title: "", userDescription: "", coordinates: [], isLocationTracked: false))

        PolylineDetailView(polyline: polylineBinding)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCancelConfirmation = true
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        do {
                            try polylineManager.finalizeWorkingPolyline()
                        } catch {
                            commitError(error)
                        }
                    }
                }
            }
            .onChange(of: polylineManager.workingPolyline) {
                if polylineManager.workingPolyline == nil {
                    onDismiss()
                    dismiss()
                }
            }
            .confirmationDialog(
                "Discard Path?",
                isPresented: $showCancelConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) {
                    polylineManager.clearWorkingPolylineProgress()
                }
            } message: {
                Text("Your in-progress path will be discarded.")
            }
    }
}

#Preview {
    withDependencies { dependencies in
        dependencies.polylinePersistenceManager.startNewWorkingPolyline(with: .random)
        dependencies.polylinePersistenceManager.appendWorkingPolylineCoordinate(.random)
    } operation: {
        CreatePolylineView(onDismiss: {}) { print($0) }
    }
}
