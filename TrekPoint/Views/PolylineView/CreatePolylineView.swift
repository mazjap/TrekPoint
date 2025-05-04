import SwiftUI

struct CreatePolylineView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PolylinePersistenceManager.self) private var polylineManager
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
                        polylineManager.clearWorkingPolylineProgress()
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
    }
}

#Preview {
    let newPolylineManager = {
        let annotationManager = PolylinePersistenceManager()
        annotationManager.startNewWorkingPolyline(with: .random)
        return annotationManager
    }()
    
    CreatePolylineView(onDismiss: {}) { print($0) }
        .environment(newPolylineManager)
}
