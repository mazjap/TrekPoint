import SwiftUI

struct CreatePolylineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding private var polyline: WorkingPolyline
    
    init(workingPolyline: Binding<WorkingPolyline>) {
        self._polyline = workingPolyline
    }
    
    var body: some View {
        NavigationStack {
            PolylineDetailView(polyline: $polyline)
                .toolbar {
                    Button("Create") {
                        modelContext.insert(
                            PolylineData(title: polyline.title, coordinates: polyline.coordinates)
                        )
                        
                        do {
                            try modelContext.save()
                            dismiss()
                        } catch {
                            print(error as NSError)
                        }
                    }
                }
        }
    }
}

#Preview {
    @Previewable @State var polyline = WorkingPolyline.example
    
    CreatePolylineView(workingPolyline: $polyline)
}
