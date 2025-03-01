import SwiftUI

struct AnnotationDetailView: View {
    private enum Storage {
        case annotationData(AnnotationData)
        case workingAnnotation(Binding<WorkingAnnotation>)
    }
    
    private let storage: Storage
    
    init(annotation: AnnotationData) {
        self.storage = .annotationData(annotation)
    }
    
    init(annotation: Binding<WorkingAnnotation>) {
        self.storage = .workingAnnotation(annotation)
    }
    
    var body: some View {
        switch storage {
        case let .annotationData(annotation):
            let bindable = Bindable(annotation)
            AnnotationDetailViewImplementation(annotation: annotation, coordinate: bindable.coordinate, title: bindable.title)
        case let .workingAnnotation(annotation):
            AnnotationDetailViewImplementation(annotation: annotation.wrappedValue, coordinate: annotation.coordinate, title: annotation.title)
        }
    }
}

fileprivate struct AnnotationDetailViewImplementation: View {
    @Binding private var coordinate: Coordinate
    @Binding private var title: String
    
    private let feature: MapFeature
    
    init(annotation: any AnnotationProvider, coordinate: Binding<Coordinate>, title: Binding<String>) {
        self.feature = .annotation(annotation)
        self._coordinate = coordinate
        self._title = title
    }
    
    var body: some View {
        VStack(spacing: 0) {
            MapPreview(feature: feature)
                .frame(height: 260)
            
            Form {
                TextField("Name this marker", text: $title)
                    .font(.title2.bold())
                
                Grid(alignment: .leading) {
                    GridRow {
                        Text("Latitude:")
                        
                        Text("Longitude:")
                    }
                    
                    GridRow {
                        TextField("", value: $coordinate.latitude, format: .number)
                        
                        TextField("", value: $coordinate.longitude, format: .number)
                    }
                    .textFieldStyle(.roundedBorder)
                }
            }
            .background {
                Color.white
                    .ignoresSafeArea(edges: .bottom)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: -10)
            }
        }
    }
}

#Preview {
    @Previewable @State var annotation = WorkingAnnotation.example
    
    AnnotationDetailView(annotation: $annotation)
}
