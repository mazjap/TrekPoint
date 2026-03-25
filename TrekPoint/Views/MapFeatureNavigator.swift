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
    @Dependency(\.modelContainer) private var container
    @Environment(\.modelContext) private var mainContext
    
    @State private var searchTask: Task<Void, Never>?
    @State private var searchText = ""
    @FocusState private var isSearchTextFocused: Bool
    @Binding private var selection: MapFeatureToPresent?
    @Binding private var selectedDetent: PresentationDetent
    
    @State private var filteredAnnotations: [AnnotationData] = []
    @State private var filteredPolylines: [PolylineData] = []
    
    private var displayedAnnotations: [AnnotationData] {
        isSearching ? filteredAnnotations : annotations
    }

    private var displayedPolylines: [PolylineData] {
        isSearching ? filteredPolylines : polylines
    }
    
    private let annotations: [AnnotationData]
    private let polylines: [PolylineData]
    private let onSelection: (MapFeature?) -> Void
    
    private var isSearching: Bool {
        !searchText.isEmpty
    }
    
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
                listContent
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                searchBar
            }
            .navigationDestination(item: $selection) { currentSelection in
                navigationDestination(for: currentSelection)
            }
        }
    }
    
    @ViewBuilder
    private var listContent: some View {
        if displayedAnnotations.isEmpty && displayedPolylines.isEmpty {
            Text(isSearching ? "No results for \"\(searchText)\"" : "No content")
        }
        
        if !displayedAnnotations.isEmpty {
            Section("Markers") {
                ForEach(displayedAnnotations) { item in
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
        
        if !displayedPolylines.isEmpty {
            Section("Paths") {
                ForEach(displayedPolylines) { item in
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
    
    private var searchBar: some View {
        // TODO: - Show search results based on ABC order (mix annotations and paths) with name matches taking priority over description matches
        // TODO: - Have closure which alerts DetailedMapView to filter features so that only features contained in current search are shown
        HStack(spacing: 10) {
            TextField("Search...", text: $searchText)
                .focused($isSearchTextFocused)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.25), in: .capsule)
                .onSubmit(of: .text) {
                    performSearch()
                }
                .onChange(of: searchText) {
                    performSearch()
                }
            
            Button {
                if searchText.isEmpty {
                    // TODO: - Show settings
                    print("Show settings")
                } else {
                    searchText = ""
                    isSearchTextFocused = false
                }
            } label: {
                Image(systemName: searchText.isEmpty ? "gearshape.fill" : "plus")
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(searchText.isEmpty ? 0 : 45))
                    .padding(6)
                    .background(Color.gray.opacity(0.25), in: .circle)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
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
    
    @ViewBuilder
    func navigationDestination(for feature: MapFeatureToPresent) -> some View {
        let onDismiss = {
            onSelection(nil)
        }
        
        Group {
            switch feature {
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
    
    private func deleteAnnotations(offsets: IndexSet) {
        withAnimation {
            var errors = [Error]()
            
            for annotation in offsets.map({ displayedAnnotations[$0] }) {
                do {
                    try annotationManager.deleteAnnotation(annotation)
                } catch {
                    errors.append(error)
                }
            }
            
            if !errors.isEmpty {
                toastManager.addBreadForToasting(.somethingWentWrong(.message("Encountered error when trying to delete annotations: \(errors)")))
            }
        }
    }
    
    private func deletePolylines(offsets: IndexSet) {
        withAnimation {
            var errors = [Error]()
            
            for polyline in offsets.map({ displayedPolylines[$0] }) {
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
    
    private func performSearch() {
        searchTask?.cancel()
        
        guard !searchText.isEmpty else {
            filteredAnnotations = []
            filteredPolylines = []
            return
        }
        
        let searchString = searchText
        let annotationSearchables = annotations.map { (id: $0.persistentModelID, title: $0.title, description: $0.userDescription) }
        let polylineSearchables = polylines.map { (id: $0.persistentModelID, title: $0.title, description: $0.userDescription) }
        
        searchTask = Task.detached {
            do {
                try await Task.sleep(for: .seconds(0.1))
            } catch {
                return
            }
            
            var annotationTitleResults = [PersistentIdentifier]()
            var annotationDescriptionResults = [PersistentIdentifier]()
            var polylineTitleResults = [PersistentIdentifier]()
            var polylineDescriptionResults = [PersistentIdentifier]()
            
            for (annotationId, title, description) in annotationSearchables {
                if title.localizedCaseInsensitiveContains(searchString) {
                    annotationTitleResults.append(annotationId)
                } else if description.localizedCaseInsensitiveContains(searchString) {
                    annotationDescriptionResults.append(annotationId)
                }
            }
            
            if Task.isCancelled {
                return
            }
            
            for (polylineId, title, description) in polylineSearchables {
                if title.localizedCaseInsensitiveContains(searchString) {
                    polylineTitleResults.append(polylineId)
                } else if description.localizedCaseInsensitiveContains(searchString) {
                    polylineDescriptionResults.append(polylineId)
                }
            }
            
            if Task.isCancelled {
                return
            }
            
            let annotationResults = annotationTitleResults + annotationDescriptionResults
            let polylineResults = polylineTitleResults + polylineDescriptionResults
            
            await MainActor.run {
                filteredAnnotations = annotationResults.compactMap { mainContext.model(for: $0) as? AnnotationData }
                filteredPolylines = polylineResults.compactMap { mainContext.model(for: $0) as? PolylineData }
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
