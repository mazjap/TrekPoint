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
    private let newAnnotation: NewAnnotationManager
    
    private let onSelection: (MapFeature?) -> Void
    
    init(
        selection: Binding<MapFeatureToPresent?>,
        newAnnotation: NewAnnotationManager,
        onSelection: @escaping (MapFeature?) -> Void
    ) {
        self._selection = selection
        self.newAnnotation = newAnnotation
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
                    Section("Annotations") {
                        ForEach(annotations) { item in
                            Button {
                                selection = .annotation(item)
                                onSelection(.annotation(item))
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundStyle(.red, .green)
                                    
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
                                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                                    
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
                            CreateAnnotationView(workingAnnotation: Bindable(newAnnotation).workingAnnotation.forceUnwrapped())
                        }
                    case .workingPolyline:
                        if true { // TODO: - Handle polyline case once implemented
                            goAwayView
                        } else {
                            CreatePolylineView(
                                workingPolyline: State(
                                    initialValue: WorkingPolyline(
                                        coordinates: [],
                                        title: ""
                                    )
                                ).projectedValue
                            )
                        }
                    }
                }
                .onDisappear {
                    selection = nil
                    onSelection(nil)
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
    MapFeatureNavigator(selection: .constant(nil), newAnnotation: .init(), onSelection: {_ in})
        .modelContainer(for: CurrentModelVersion.models, inMemory: true)
}
