import SwiftUI

struct MapFeatureNavigator: View {
    let annotations: [AnnotationData]
    let polylines: [PolylineData]
    let onSelection: (MapFeature) -> Void
    let onDeleteAnnotations: (IndexSet) -> Void
    let onDeletePolylines: (IndexSet) -> Void
    
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
                            NavigationLink {
                                ModifyAnnotationView(annotation: item)
                                    .onAppear {
                                        onSelection(.annotation(item))
                                    }
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundStyle(.red, .green)
                                    
                                    Text(item.title)
                                }
                            }
                        }
                        .onDelete(perform: onDeleteAnnotations)
                    }
                }
                
                if !polylines.isEmpty {
                    Section("Paths") {
                        ForEach(polylines) { item in
                            NavigationLink {
                                ModifyPolylineView(polyline: item)
                                    .onAppear {
                                        onSelection(.polyline(item))
                                    }
                            } label: {
                                HStack {
                                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                                    
                                    Text(item.title)
                                }
                            }
                        }
                        .onDelete(perform: onDeletePolylines)
                    }
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
}

#Preview {
    @Previewable @State var annotations = [AnnotationData]()
    @Previewable @State var polylines = [PolylineData]()
    
    MapFeatureNavigator(
        annotations: annotations,
        polylines: polylines) { _ in
            
        } onDeleteAnnotations: { indices in
            annotations.remove(atOffsets: indices)
        } onDeletePolylines: { indices in
            polylines.remove(atOffsets: indices)
        }

}
