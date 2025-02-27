import SwiftUI

struct ModifyAnnotationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var annotation: AnnotationData
    
    init(annotation: AnnotationData) {
        self._annotation = State(wrappedValue: annotation)
    }
    
    var body: some View {
        NavigationStack {
            AnnotationDetailView(coordinate: $annotation.coordinate, title: $annotation.title)
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
    ModifyAnnotationView(annotation: .init(title: "Test", coordinate: .init(latitude: 0, longitude: 0)))
}
