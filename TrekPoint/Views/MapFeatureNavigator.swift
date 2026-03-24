import SwiftUI
import SwiftData
import Dependencies

enum MapFeatureToPresent: Hashable {
    case annotation(AnnotationData)
    case polyline(PolylineData)
    case workingAnnotation
    case workingPolyline
}

struct MapFeatureNavigator: View {
    @Dependency(\.annotationPersistenceManager) private var annotationManager
    @Dependency(\.polylinePersistenceManager) private var polylineManager
    @Dependency(\.toastManager) private var toastManager
    @Environment(\.isSearching) private var isSearching
    
    @State private var searchText = ""
    @FocusState private var isSearchTextFocused: Bool
    @Binding private var selection: MapFeatureToPresent?
    @Binding private var selectedDetent: PresentationDetent
    
    private let annotations: [AnnotationData]
    private let polylines: [PolylineData]
    private let onSelection: (MapFeature?) -> Void
    
    init(
        selection: Binding<MapFeatureToPresent?>,
        selectedDetent: Binding<PresentationDetent>,
        annotations: [AnnotationData],
        polylines: [PolylineData],
        onSelection: @escaping (MapFeature?) -> Void
    ) {
        self._selection = selection
        self._selectedDetent = selectedDetent
        self.annotations = annotations
        self.polylines = polylines
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
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(spacing: 10) {
                    TextField("Search...", text: $searchText)
                        .focused($isSearchTextFocused)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .modifier(VersionSpecificTextFieldBackground())
                    
                    Button {
                        if isSearchTextFocused {
                            isSearchTextFocused = false
                        } else {
                            // TODO: - Show settings
                        }
                    } label: {
                        Image(systemName: isSearchTextFocused ? "xmark" : "gearshape.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(VersionSpecificButtonStyle())
                }
                .padding(.horizontal, 18)
                .frame(height: PresentationDetent.smallDetentHeight)
                .padding(.top, 2)
                .onChange(of: isSearchTextFocused) {
                    if isSearchTextFocused {
                        selectedDetent = .largeWithoutScaleEffect
                    } else {
                        selectedDetent = .medium
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
    @Previewable @State var detent = PresentationDetent.small
    
    Color.red.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            MapFeatureNavigator(
                selection: .constant(nil),
                selectedDetent: $detent,
                annotations: [.preview],
                polylines: [.preview],
                onSelection: { _ in }
            )
            .presentationDetents(.defaultMapSheetDetents)
        }
}

fileprivate struct VersionSpecificButtonStyle: PrimitiveButtonStyle {
    @available(iOS 26, *)
    static private let iOS26Style = GlassButtonStyle()
    
    static private let backupStyle = DefaultButtonStyle()
    
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26, *) {
            Self.iOS26Style.makeBody(configuration: configuration)
        } else {
            Self.backupStyle.makeBody(configuration: configuration)
        }
    }
}


fileprivate struct VersionSpecificTextFieldBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular, in: .capsule)
        } else {
            content.background(.gray.opacity(0.25), in: .capsule)
        }
    }
}
