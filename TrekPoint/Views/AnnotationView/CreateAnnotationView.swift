import SwiftUI
import SwiftData
import struct CoreLocation.CLLocationCoordinate2D

fileprivate enum NavigationState {
    case viewing, creating, canceling
}

struct CreateAnnotationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var navigationState: NavigationState = .viewing
    @Binding private var annotation: WorkingAnnotation?
    
    private let onCreated: () -> Bool
    private let onDiscarded: () -> Void
    
    init(workingAnnotation: Binding<WorkingAnnotation>, onCreated: @escaping () -> Bool, onDiscarded: @escaping () -> Void) {
        self.init(
            workingAnnotation: Binding<WorkingAnnotation?> {
                workingAnnotation.wrappedValue
            } set: {
                if let newValue = $0 {
                    workingAnnotation.wrappedValue = newValue
                }
            },
            onCreated: onCreated,
            onDiscarded: onDiscarded
        )
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
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            navigationState = .canceling
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            if onCreated() {
                                navigationState = .creating
                                dismiss()
                            }
                        }
                    }
                }
                .navigationBarBackButtonHidden()
                .onDisappear {
                    switch navigationState {
                    case .creating:
                        // Do nothing - created successfully
                        break
                    case .canceling:
                        onDiscarded()
                    case .viewing:
                        // When PHPhoto UI sheet is dismissed, it dismisses this sheet too for some reason
                        break
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
