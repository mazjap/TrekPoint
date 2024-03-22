import SwiftUI
import SwiftData

struct CreateAnnotationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding private var coordinate: Coordinate
    @State private var title = ""
    
    init(coordinate: Binding<Coordinate>) {
        self._coordinate = coordinate
    }
    
    var body: some View {
        NavigationStack {
            AnnotationDetailView(coordinate: $coordinate, title: $title)
                .toolbar {
                    Button("Create") {
                        modelContext.insert(
                            AnnotationData(title: title, coordinate: coordinate)
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
    struct CreateAnnotationPreview: View {
        @State private var coordinate = Coordinate(latitude: .random(in: -90...90), longitude: .random(in: -180...180))
        
        var body: some View {
            CreateAnnotationView(coordinate: $coordinate)
        }
    }
    
    return CreateAnnotationPreview()
}
