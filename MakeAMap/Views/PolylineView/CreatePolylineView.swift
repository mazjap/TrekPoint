import SwiftUI

struct CreatePolylineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding private var coordinates: [Coordinate]
    @State private var title = ""
    
    init(coordinates: Binding<[Coordinate]>) {
        self._coordinates = coordinates
    }
    
    var body: some View {
        NavigationStack {
            PolylineDetailView(coordinates: $coordinates, title: $title)
                .toolbar {
                    Button("Create") {
                        modelContext.insert(
                            PolylineData(title: title, coordinates: coordinates)
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
    @Previewable @State var coordinates = PolylineData.example.coordinates
    
    CreatePolylineView(coordinates: $coordinates)
}
