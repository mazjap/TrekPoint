import SwiftUI
import AVKit

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
            AnnotationDetailViewImplementation(annotation: annotation, coordinate: bindable.coordinate, title: bindable.title, attachments: bindable.attachments, notes: bindable.userDescription)
        case let .workingAnnotation(annotation):
            AnnotationDetailViewImplementation(annotation: annotation.wrappedValue, coordinate: annotation.coordinate, title: annotation.title, attachments: annotation.attachments, notes: annotation.userDescription)
        }
    }
}

fileprivate struct AnnotationDetailViewImplementation: View {
    @State private var isBrowsingPhotos = false
    @Binding private var coordinate: Coordinate
    @Binding private var title: String
    @Binding private var attachments: [Attachment]
    @Binding private var notes: String
    
    private let feature: MapFeature
    
    init(annotation: any AnnotationProvider, coordinate: Binding<Coordinate>, title: Binding<String>, attachments: Binding<[Attachment]>, notes: Binding<String>) {
        self.feature = .annotation(annotation)
        self._coordinate = coordinate
        self._title = title
        self._attachments = attachments
        self._notes = notes
    }
    
    var body: some View {
        Form {
            MapPreview(feature: feature)
                .frame(height: 260)
            
            TextField("Name this marker", text: $title)
                .font(.title2.bold())
                .overlay {
                    if title.isEmpty {
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
                    TextField("", value: $coordinate.latitude, format: .number)
                    
                    TextField("", value: $coordinate.longitude, format: .number)
                }
                .textFieldStyle(.roundedBorder)
            }
            
            DisclosureGroup("Attachments") {
                TabView {
                    AttachmentsView(attachments: $attachments)
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 350)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            DisclosureGroup("Notes") {
                HStack(spacing: 0) {
                    Divider()
                    
                    TextEditor(text: $notes)
                        .frame(height: 200)
                }
            }
        }
        .background {
            Color.white
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.1), radius: 10, y: -10)
        }
    }
}

#Preview {
    @Previewable @State var annotation = WorkingAnnotation.example
    
    AnnotationDetailView(annotation: $annotation)
}
