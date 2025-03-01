import SwiftUI

struct ModifyPolylineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    private let polyline: PolylineData
    
    init(polyline: PolylineData) {
        self.polyline = polyline
    }
    
    var body: some View {
        NavigationStack {
            PolylineDetailView(polyline: polyline)
                .toolbar {
                    Button("Save") {
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
    ModifyPolylineView(polyline: PolylineData(title: WorkingPolyline.example.title, coordinates: WorkingPolyline.example.coordinates))
}

