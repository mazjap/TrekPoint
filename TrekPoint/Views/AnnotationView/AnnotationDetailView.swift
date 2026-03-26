import SwiftUI
import AVKit

struct AnnotationDetailView: View {
    private enum Storage {
        case annotationData(Bindable<AnnotationData>)
        case workingAnnotation(Binding<WorkingAnnotation>)
        
        var wrappedValue: any AnnotationProvider {
            switch self {
            case let .annotationData(annotation): annotation.wrappedValue
            case let .workingAnnotation(annotation): annotation.wrappedValue
            }
        }
        
        var coordinate: Binding<Coordinate> {
            switch self {
            case let .annotationData(annotation): annotation.coordinate
            case let .workingAnnotation(annotation): annotation.coordinate
            }
        }
        
        var title: Binding<String> {
            switch self {
            case let .annotationData(annotation): annotation.title
            case let .workingAnnotation(annotation): annotation.title
            }
        }
        
        var userDescription: Binding<String> {
            switch self {
            case let .annotationData(annotation): annotation.userDescription
            case let .workingAnnotation(annotation): annotation.userDescription
            }
        }
        
        var attachments: Binding<[Attachment]> {
            switch self {
            case let .annotationData(annotation): annotation.attachments
            case let .workingAnnotation(annotation): annotation.attachments
            }
        }
        
        var type: AnnotationType {
            switch self {
            case let .annotationData(annotation): .model(annotation.wrappedValue)
            case let .workingAnnotation(annotation): .working(annotation.wrappedValue)
            }
        }
    }
    
    @State private var previewId = UUID()
    @State private var isBrowsingPhotos = false
    
    private let storage: Storage
    
    init(annotation: AnnotationData) {
        self.storage = .annotationData(Bindable(annotation))
    }
    
    init(annotation: Binding<WorkingAnnotation>) {
        self.storage = .workingAnnotation(annotation)
    }
    
    var body: some View {
        Form {
            AnnotationMapPreview(annotation: storage.wrappedValue)
                .id(previewId)
                .frame(height: 260)
                .onChange(of: storage.coordinate.wrappedValue) {
                    previewId = UUID()
                }
            
            TextField("Name this marker", text: storage.title)
                .font(.title2.bold())
                .overlay {
                    if storage.title.wrappedValue.isEmpty {
                        Color.red.opacity(0.2)
                            .allowsHitTesting(false)
                            // TODO: - Don't use magic number
                            .padding(.horizontal, -20)
                            .padding(.vertical, -10)
                    }
                }
            
            Grid(alignment: .leading) {
                GridRow {
                    Text("Latitude:")
                    
                    Text("Longitude:")
                }
                
                GridRow {
                    TextField("", value: storage.coordinate.latitude, format: .number)
                    
                    TextField("", value: storage.coordinate.longitude, format: .number)
                }
                .textFieldStyle(.roundedBorder)
            }
            
            DisclosureGroup("Attachments") {
                AttachmentsView(annotation: storage.type)
                    .frame(height: 350)
            }
            
            DisclosureGroup("Notes") {
                HStack(spacing: 0) {
                    Divider()
                    
                    TextEditor(text: storage.userDescription)
                        .frame(height: 200)
                }
            }
        }
        .navigationTitle(storage.title.wrappedValue)
    }
}

#Preview {
    @Previewable @State var annotation = WorkingAnnotation.example
    
    AnnotationDetailView(annotation: $annotation)
}
