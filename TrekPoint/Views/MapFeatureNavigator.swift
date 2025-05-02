import SwiftUI
import SwiftData

enum MapFeatureToPresent: Hashable {
    case annotation(AnnotationData)
    case polyline(PolylineData)
    case workingAnnotation
    case workingPolyline
}

struct MapFeatureNavigator: View {
    @Binding private var selection: MapFeatureToPresent?
    
    private let annotations: [AnnotationData]
    private let polylines: [PolylineData]
    private let annotationManager: AnnotationPersistenceManager
    private let polylineManager: PolylinePersistenceManager
    private let toastManager: ToastManager
    private let onSelection: (MapFeature?) -> Void
    
    init(
        selection: Binding<MapFeatureToPresent?>,
        annotations: [AnnotationData],
        polylines: [PolylineData],
        annotationManager: AnnotationPersistenceManager,
        polylineManager: PolylinePersistenceManager,
        toastManager: ToastManager,
        onSelection: @escaping (MapFeature?) -> Void
    ) {
        self._selection = selection
        self.annotations = annotations
        self.polylines = polylines
        self.annotationManager = annotationManager
        self.polylineManager = polylineManager
        self.toastManager = toastManager
        self.onSelection = onSelection
    }
    
    var body: some View {
        // TODO: - Add sorting options (sort by date, sort by type of feature, etc.)
        NavigationStack {
            List {
                if annotations.isEmpty && polylines.isEmpty {
                    Text("No content")
                }
                
                if !annotations.isEmpty {
                    Section("Markers") {
                        ForEach(annotations) { item in
                            Button {
                                selection = .annotation(item)
                                onSelection(.annotation(item))
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundStyle(.orange, .green)
                                    
                                    Text(item.title)
                                }
                            }
                        }
                        .onDelete(perform: deleteAnnotations)
                    }
                }
                
                if !polylines.isEmpty {
                    Section("Paths") {
                        ForEach(polylines) { item in
                            Button {
                                selection = .polyline(item)
                                onSelection(.polyline(item))
                            } label: {
                                HStack {
                                    Image(systemName: "scribble")
                                        .foregroundStyle(.red)
                                    
                                    Text(item.title)
                                }
                            }
                        }
                        .onDelete(perform: deletePolylines)
                    }
                }
            }
            .navigationDestination(item: $selection) { currentSelection in
                let onDismiss = {
                    onSelection(nil)
                }
                
                Group {
                    switch currentSelection {
                    case let .annotation(annotation):
                        ModifyAnnotationView(annotation: annotation, onDismiss: onDismiss, commitError: toastManager.commitFeatureCreationError)
                    case let .polyline(polyline):
                        ModifyPolylineView(polyline: polyline, onDismiss: onDismiss, commitError: toastManager.commitFeatureCreationError)
                    case .workingAnnotation:
                        CreateAnnotationView(onDismiss: onDismiss, commitError: toastManager.commitFeatureCreationError)
                    case .workingPolyline:
                        CreatePolylineView(onDismiss: onDismiss, commitError: toastManager.commitFeatureCreationError)
                    }
                }
                .navigationBarBackButtonHidden()
            }
            .padding(.top, -20)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .navigationTitle("My Items")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func deleteAnnotations(offsets: IndexSet) {
        withAnimation {
            var errors = [Error]()
            
            for annotation in offsets.map({ annotations[$0] }) {
                do {
                    try annotationManager.deleteAnnotation(annotation)
                } catch {
                    errors.append(error)
                }
            }
            
            if !errors.isEmpty {
                toastManager.addBreadForToasting(.somethingWentWrong(.message("Encountered error when trying to delete polylines: \(errors)")))
            }
        }
    }
    
    private func deletePolylines(offsets: IndexSet) {
        withAnimation {
            var errors = [Error]()
            
            for polyline in offsets.map({ polylines[$0] }) {
                do {
                    try polylineManager.deletePolyline(polyline)
                } catch {
                    errors.append(error)
                }
            }
            
            if !errors.isEmpty {
                toastManager.addBreadForToasting(.somethingWentWrong(.message("Encountered error when trying to delete polylines: \(errors)")))
            }
        }
    }
}

#Preview {
    MapFeatureNavigator(
        selection: .constant(nil),
        annotations: [ModelContainer.previewAnnotation],
        polylines: [ModelContainer.previewPolyline],
        annotationManager: AnnotationPersistenceManager(modelContainer: .preview, attachmentStore: AttachmentStore()),
        polylineManager: PolylinePersistenceManager(modelContainer: .preview),
        toastManager: .init(),
        onSelection: { _ in }
    )
}
