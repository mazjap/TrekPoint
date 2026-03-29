import SwiftUI
import Dependencies
import SwiftData

@Observable
@MainActor
class FeatureLibraryCoordinator {
    var searchText = ""
    var filteredAnnotations: [AnnotationData] = []
    var filteredPolylines: [PolylineData] = []
    var isSettingsSheetPresented = false
    
    var onSelection: ((ResolvedMapFeature?) -> Void)?
    var onSearchFocusChanged: ((Bool) -> Void)?
    var onSettingsPresented: (() -> Void)?
    var onSettingsDismissed: (() -> Void)?
    
    var isSearching: Bool { !searchText.isEmpty }
    
    @ObservationIgnored @Dependency(\.annotationPersistenceManager) private var annotationManager
    @ObservationIgnored @Dependency(\.polylinePersistenceManager) private var polylineManager
    @ObservationIgnored @Dependency(\.toastManager) private var toastManager
    @ObservationIgnored @Dependency(\.modelContainer) private var container
    
    private var searchTask: Task<Void, Never>?
    
    @MainActor
    private var mainContext: ModelContext { container.mainContext }
    
    func displayedAnnotations(all annotations: [AnnotationData]) -> [AnnotationData] {
        isSearching ? filteredAnnotations : annotations
    }
    
    func displayedPolylines(all polylines: [PolylineData]) -> [PolylineData] {
        isSearching ? filteredPolylines : polylines
    }
    
    func handleSearchTextChange(annotations: [AnnotationData], polylines: [PolylineData]) {
        performSearch(annotations: annotations, polylines: polylines)
    }
    
    func deleteAnnotations(at offsets: IndexSet, in annotations: [AnnotationData]) {
        withAnimation {
            var errors = [Error]()
            let displayed = displayedAnnotations(all: annotations)
            
            for annotation in offsets.map({ displayed[$0] }) {
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
    
    func deletePolylines(at offsets: IndexSet, in polylines: [PolylineData]) {
        withAnimation {
            var errors = [Error]()
            let displayed = displayedPolylines(all: polylines)
            
            for polyline in offsets.map({ displayed[$0] }) {
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
    
    func handleFeatureCreationError(_ error: Error) {
        toastManager.commitFeatureCreationError(error)
    }
    
    func handleSearchFocusChange(isFocused: Bool) {
        onSearchFocusChanged?(isFocused)
    }
    
    func handleSettingsTapped() {
        isSettingsSheetPresented = true
        onSettingsPresented?()
    }
    
    func handleSettingsDismissed() {
        // Not necessarily needed bc SwiftUI's dismiss() sets the binding to false, but better to be consistent
        isSettingsSheetPresented = false
        onSettingsDismissed?()
    }
    
    private func performSearch(annotations: [AnnotationData], polylines: [PolylineData]) {
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
                self.filteredAnnotations = annotationResults.compactMap { self.mainContext.model(for: $0) as? AnnotationData }
                self.filteredPolylines = polylineResults.compactMap { self.mainContext.model(for: $0) as? PolylineData }
            }
        }
    }
}
