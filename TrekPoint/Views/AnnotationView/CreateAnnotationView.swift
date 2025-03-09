import SwiftUI
import SwiftData
import struct CoreLocation.CLLocationCoordinate2D

struct CreateAnnotationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var wasCreated = false
    @Binding private var annotation: WorkingAnnotation?
    
    private let onCreated: () -> Bool
    private let onDiscarded: () -> Void
    
    init(workingAnnotation: Binding<WorkingAnnotation>, onCreated: @escaping () -> Bool, onDiscarded: @escaping () -> Void) {
        self.init(workingAnnotation: Binding<WorkingAnnotation?> { workingAnnotation.wrappedValue } set: { if let newValue = $0 { workingAnnotation.wrappedValue = newValue } }, onCreated: onCreated, onDiscarded: onDiscarded)
    }
    
    init(workingAnnotation: Binding<WorkingAnnotation?>, onCreated: @escaping () -> Bool, onDiscarded: @escaping () -> Void) {
        self._annotation = workingAnnotation
        self.onCreated = onCreated
        self.onDiscarded = onDiscarded
    }
    
    var body: some View {
        NavigationStack {
            let annotationBinding = $annotation.safelyUnwrapped(.init(coordinate: .random, title: ""))
            
            AnnotationDetailView(annotation: annotationBinding)
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
            CreateAnnotationView(workingAnnotation: $annotation) {true} onDiscarded: {}
        }
    }
    
    return CreateAnnotationPreview()
}
