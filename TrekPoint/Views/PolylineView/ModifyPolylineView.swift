import SwiftUI

struct ModifyPolylineView: View {
    @Environment(PolylinePersistenceManager.self) private var polylineManager
    @Environment(\.dismiss) private var dismiss
    private let polyline: PolylineData
    private let onDismiss: () -> Void
    private let commitError: (Error) -> Void
    
    init(polyline: PolylineData, onDismiss: @escaping () -> Void, commitError: @escaping (Error) -> Void) {
        self.polyline = polyline
        self.onDismiss = onDismiss
        self.commitError = commitError
    }
    
    var body: some View {
        PolylineDetailView(polyline: polyline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        polylineManager.discardChanges()
                        onDismiss()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try polylineManager.save()
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
    ModifyPolylineView(polyline: PolylineData(title: WorkingPolyline.example.title, coordinates: WorkingPolyline.example.coordinates, isLocationTracked: false), onDismiss: {})  { print($0) }
        .environment(PolylinePersistenceManager(modelContainer: .preview))
}

