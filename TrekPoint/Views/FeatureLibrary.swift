import SwiftUI
import SwiftData
import Dependencies

struct FeatureLibrary: View {
    @FocusState private var isSearchFocused: Bool
    @Bindable private var coordinator: FeatureLibraryCoordinator
    private let selection: ResolvedMapFeature?
    private let annotations: [AnnotationData]
    private let polylines: [PolylineData]
    
    private var navigationPath: Binding<[ResolvedMapFeature]> {
        Binding {
            selection.map { [$0] } ?? []
        } set: { newPath in
            coordinator.handleFeatureSelection(newPath.last)
        }
    }
    
    private var displayedAnnotations: [AnnotationData] {
        coordinator.displayedAnnotations(all: annotations)
    }
    
    private var displayedPolylines: [PolylineData] {
        coordinator.displayedPolylines(all: polylines)
    }
    
    init(
        coordinator: FeatureLibraryCoordinator,
        selection: ResolvedMapFeature?,
        annotations: [AnnotationData],
        polylines: [PolylineData]
    ) {
        self._coordinator = Bindable(coordinator)
        self.selection = selection
        self.annotations = annotations
        self.polylines = polylines
    }
    
    var body: some View {
        // TODO: - Add sorting options (sort by date, sort by type of feature, etc.)
        NavigationStack(path: navigationPath) {
            List {
                listContent
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top, spacing: 0) {
                searchBar
            }
            .navigationDestination(for: ResolvedMapFeature.self) { feature in
                navigationDestination(for: feature)
            }
        }
        .sheet(
            isPresented: $coordinator.isSettingsSheetPresented,
            onDismiss: {
                coordinator.handleSettingsDismissed()
            },
            content: {
                SettingsView()
                    .interactiveDismissDisabled()
                    .presentationDetents([.medium])
            }
        )
    }
    
    @ViewBuilder
    private var listContent: some View {
        if displayedAnnotations.isEmpty && displayedPolylines.isEmpty {
            Text(coordinator.isSearching ? "No results for \"\(coordinator.searchText)\"" : "No content")
        }
        
        if !displayedAnnotations.isEmpty {
            Section("Markers") {
                ForEach(displayedAnnotations) { item in
                    Button {
                        coordinator.handleFeatureSelection(.annotation(item))
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(.orange, .green)
                            
                            Text(item.title)
                        }
                    }
                }
                .onDelete { indexSet in
                    coordinator.deleteAnnotations(at: indexSet, in: annotations)
                }
            }
        }
        
        if !displayedPolylines.isEmpty {
            Section("Paths") {
                ForEach(displayedPolylines) { item in
                    Button {
                        coordinator.handleFeatureSelection(.polyline(item))
                    } label: {
                        HStack {
                            Image(systemName: "scribble")
                                .foregroundStyle(.red)
                            
                            Text(item.title)
                        }
                    }
                }
                .onDelete { indexSet in
                    coordinator.deletePolylines(at: indexSet, in: polylines)
                }
            }
        }
    }
    
    private var searchBar: some View {
        // TODO: - Show search results based on ABC order (mix annotations and paths) with name matches taking priority over description matches
        // TODO: - Have closure which alerts DetailedMapView to filter features so that only features contained in current search are shown
        HStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.primary)
                
                TextField("", text: $coordinator.searchText, prompt: Text("Search...").foregroundStyle(.gray))
                    .focused($isSearchFocused)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .versionSpecificBackground(in: .capsule)
            .onTapGesture {
                isSearchFocused = true
            }
            .onChange(of: coordinator.searchText) {
                coordinator.handleSearchTextChange(annotations: annotations, polylines: polylines)
            }
            .onChange(of: isSearchFocused) {
                coordinator.handleSearchFocusChange(isFocused: isSearchFocused)
            }
            
            Button {
                if coordinator.searchText.isEmpty {
                    coordinator.handleSettingsTapped()
                } else {
                    coordinator.searchText = ""
                    isSearchFocused = false
                }
            } label: {
                Image(systemName: coordinator.searchText.isEmpty ? "gearshape.fill" : "plus")
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(coordinator.searchText.isEmpty ? 0 : 45))
                    .padding(6)
                    .versionSpecificBackground(in: .circle)
                    .padding(.vertical, 15)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .frame(height: PresentationDetent.smallDetentHeight)
        .padding(.top, 2)
    }
    
    @ViewBuilder
    func navigationDestination(for feature: ResolvedMapFeature) -> some View {
        let onDismiss: () -> Void = {
            coordinator.handleFeatureSelection(nil)
        }

        let onCancel: () -> Void = {
            switch feature {
            case .workingAnnotation:
                coordinator.onNewFeatureCancellation?(.annotation)
            case .workingPolyline:
                coordinator.onNewFeatureCancellation?(.polyline)
            default:
                coordinator.handleFeatureSelection(nil)
            }
        }

        let commitError = { (error: Error) in
            coordinator.handleFeatureCreationError(error)
        }

        Group {
            switch feature {
            case let .annotation(annotation):
                ModifyAnnotationView(annotation: annotation, onDismiss: onDismiss, commitError: commitError)
            case let .polyline(polyline):
                ModifyPolylineView(polyline: polyline, onDismiss: onDismiss, commitError: commitError)
            case .workingAnnotation:
                CreateAnnotationView(onDismiss: onDismiss, onCancel: onCancel, commitError: commitError)
            case .workingPolyline:
                CreatePolylineView(onDismiss: onDismiss, onCancel: onCancel, commitError: commitError)
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    @Previewable @State var detent = PresentationDetent.tpSmall
    
    Color.red.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            FeatureLibrary(
                coordinator: .init(),
                selection: nil,
                annotations: [.preview],
                polylines: [.preview]
            )
            .presentationDetents(.defaultMapSheetDetents)
        }
}
