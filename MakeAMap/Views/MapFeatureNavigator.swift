import SwiftUI
import SwiftData

enum MapFeatureToPresent: Hashable {
    case annotation(AnnotationData)
    case polyline(PolylineData)
    case workingAnnotation
    case workingPolyline
}

struct MapFeatureNavigator: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var annotations: [AnnotationData]
    @Query private var polylines: [PolylineData]
    
    @Binding private var selection: MapFeatureToPresent?
    @Binding private var isInEditingMode: Bool
    @Binding private var toastReasons: [ToastReason]
    
    private let newAnnotation: NewAnnotationManager
    private let newPolyline: NewPolylineManager
    
    private let onSelection: (MapFeature?) -> Void
    private let onTrackingPolylineCreated: () -> Void
    
    init(
        selection: Binding<MapFeatureToPresent?>,
        isInEditingMode: Binding<Bool>,
        toastReasons: Binding<[ToastReason]>,
        newAnnotation: NewAnnotationManager,
        newPolyline: NewPolylineManager,
        onSelection: @escaping (MapFeature?) -> Void,
        onTrackingPolylineCreated: @escaping () -> Void
    ) {
        self._selection = selection
        self._isInEditingMode = isInEditingMode
        self._toastReasons = toastReasons
        self.newAnnotation = newAnnotation
        self.newPolyline = newPolyline
        self.onSelection = onSelection
        self.onTrackingPolylineCreated = onTrackingPolylineCreated
    }
    
    var body: some View {
        // TODO: - Add sorting options (sort by date, sort by type of feature, etc.)
        NavigationStack {
            List {
                if annotations.isEmpty && polylines.isEmpty {
                    Text("No content")
                }
                
                if !annotations.isEmpty {
                    Section("Annotations") {
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
                let goAwayView = Color.clear.onAppear {
                    selection = nil
                    onSelection(nil)
                }
                
                Group {
                    switch currentSelection {
                    case let .annotation(annotation):
                        ModifyAnnotationView(annotation: annotation)
                    case let .polyline(polyline):
                        ModifyPolylineView(polyline: polyline)
                    case .workingAnnotation:
                        if newAnnotation.workingAnnotation == nil {
                            goAwayView
                        } else {
                            CreateAnnotationView(workingAnnotation: Bindable(newAnnotation).workingAnnotation) {
                                
                                do {
                                    try modelContext.insert(newAnnotation.finalize())
                                    
                                    return true
                                } catch let annotationError as AnnotationFinalizationError {
                                    toastReasons.append( .annotationCreationError(annotationError))
                                } catch {
                                    // TODO: - Send to some analytics service
                                    toastReasons.append(.somethingWentWrong(.error(error)))
                                }
                                
                                return false
                            } onDiscarded: {
                                newAnnotation.clearProgress()
                            }
                        }
                    case .workingPolyline:
                        if newPolyline.workingPolyline == nil {
                            goAwayView
                        } else {
                            CreatePolylineView(workingPolyline: Bindable(newPolyline).workingPolyline) {
                                do {
                                    let shouldPhoneHome = newPolyline.isTrackingPolyline
                                    try modelContext.insert(newPolyline.finalize())
                                    
                                    if shouldPhoneHome {
                                        onTrackingPolylineCreated()
                                    }
                                    
                                    return true
                                } catch let polylineError as PolylineFinalizationError {
                                    toastReasons.append(.polylineCreationError(polylineError))
                                } catch {
                                    // TODO: - Send to some analytics service
                                    toastReasons.append(.somethingWentWrong(.error(error)))
                                }
                                
                                return false
                            } onDiscarded: {
                                newPolyline.clearProgress()
                            }
                        }
                    }
                }
                .onDisappear {
                    selection = nil
                    onSelection(nil)
                    isInEditingMode = false
                }
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
            for index in offsets {
                modelContext.delete(annotations[index])
            }
        }
    }
    
    private func deletePolylines(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(polylines[index])
            }
        }
    }
}

#Preview {
    MapFeatureNavigator(selection: .constant(nil), isInEditingMode: .constant(false), toastReasons: .constant([]), newAnnotation: .init(), newPolyline: .init(), onSelection: {_ in}, onTrackingPolylineCreated: {})
        .modelContainer(for: CurrentModelVersion.models, inMemory: true) { phase in
            switch phase {
            case let .success(container):
                let context = ModelContext(container)
                
                context.insert(AnnotationData(title: "annotation", coordinate: WorkingAnnotation.example.coordinate))
                context.insert(PolylineData(title: "path", coordinates: WorkingPolyline.example.coordinates, isLocationTracked: false))
                
                try! context.save()
            case let .failure(error):
                print(error)
            }
        }
}
