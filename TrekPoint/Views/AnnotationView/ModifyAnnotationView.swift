import SwiftUI

struct ModifyAnnotationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    private let annotation: AnnotationData
    
    init(annotation: AnnotationData) {
        self.annotation = annotation
    }
    
    var body: some View {
        NavigationStack {
            AnnotationDetailView(annotation: annotation)
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
    ModifyAnnotationView(annotation: AnnotationData(title: WorkingAnnotation.example.title, coordinate: WorkingAnnotation.example.coordinate))
}
