import SwiftUI

struct CreatePolylineView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding private var polyline: WorkingPolyline?
    @State private var wasCreated = false
    private let onCreated: () -> Bool
    private let onDiscarded: () -> Void
    
    init(workingPolyline: Binding<WorkingPolyline>, onCreated: @escaping () -> Bool, onDiscarded: @escaping () -> Void) {
        self.init(workingPolyline: Binding<WorkingPolyline?> {
            workingPolyline.wrappedValue
        } set: {
            if let newValue = $0 {
                workingPolyline.wrappedValue = newValue
            }
        }, onCreated: onCreated, onDiscarded: onDiscarded)
    }
    
    init(workingPolyline: Binding<WorkingPolyline?>, onCreated: @escaping () -> Bool, onDiscarded: @escaping () -> Void) {
        self._polyline = workingPolyline
        self.onCreated = onCreated
        self.onDiscarded = onDiscarded
    }
    
    var body: some View {
        let polylineBinding = $polyline.safelyUnwrapped(.init(coordinates: [], title: ""))
        
        PolylineDetailView(polyline: polylineBinding)
            .toolbar {
                Button("Create") {
                    if onCreated() {
                        wasCreated = true
                        dismiss()
                    }
                }
            }
            .onDisappear {
                if !wasCreated {
                    onDiscarded()
                }
            }
    }
}

#Preview {
    @Previewable @State var polyline = WorkingPolyline.example
    
    CreatePolylineView(workingPolyline: $polyline) {true} onDiscarded: {}
}
