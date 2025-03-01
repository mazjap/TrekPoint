import SwiftUI
import SwiftData
import struct CoreLocation.CLLocationCoordinate2D

struct CreateAnnotationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding private var annotation: WorkingAnnotation
    
    init(workingAnnotation: Binding<WorkingAnnotation>) {
        self._annotation = workingAnnotation
    }
    
    var body: some View {
        NavigationStack {
            AnnotationDetailView(annotation: $annotation)
                .toolbar {
                    Button("Create") {
                        modelContext.insert(
                            AnnotationData(title: annotation.title, coordinate: annotation.coordinate)
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
        @State private var annotation = WorkingAnnotation(
            coordinate: Coordinate(
                latitude: .random(in: -90...90),
                longitude: .random(in: -180...180)
            ),
            title: ""
        )
        
        var body: some View {
            CreateAnnotationView(workingAnnotation: $annotation)
        }
    }
    
    return CreateAnnotationPreview()
}
