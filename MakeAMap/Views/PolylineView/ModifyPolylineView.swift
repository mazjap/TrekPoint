import SwiftUI

struct ModifyPolylineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var polyline: PolylineData
    
    init(polyline: PolylineData) {
        self._polyline = State(wrappedValue: polyline)
    }
    
    var body: some View {
        NavigationStack {
            PolylineDetailView(coordinates: $polyline.coordinates, title: $polyline.title)
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
    ModifyPolylineView(polyline: .example)
}

