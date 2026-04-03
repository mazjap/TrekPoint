import SwiftUI
import MapboxMaps
import Dependencies
import Combine

enum PendingCancelAction {
    case annotation, polyline(isTracked: Bool)
    case hideLocationWhileTracking // User tried to turn location off while still path tracking
    
    init(action: PendingSheetCancelAction) {
        switch action {
        case .annotation:
            self = .annotation
        case .polyline(let isTracked):
            self = .polyline(isTracked: isTracked)
        }
    }
}

enum PendingSheetCancelAction {
    case annotation, polyline(isTracked: Bool)
}

@Observable
@MainActor
class MapCoordinator {
    var cameraPosition: Viewport = .idle
    var selectedMapFeature: ResolvedMapFeature?
    var selectedDetent: PresentationDetent = .tpSmall
    var featureLibraryCoordinator = FeatureLibraryCoordinator()
    var styleWasInitiallyLoaded = false
    var pendingCancelAction: PendingCancelAction? = nil
    var showCancelConfirmation: Bool = false
    var showSheet = false
    
    // TODO: - Handle name changes as well
    var annotationFeatureCollection = FeatureCollection(features: [])
    var polylineFeatureCollection = FeatureCollection(features: [])
    
    @ObservationIgnored private var shelvedPresentationDetent: PresentationDetent?
    
    @ObservationIgnored @Dependency(\.appSettings) private var appSettings
    @ObservationIgnored @Dependency(\.annotationPersistenceManager) fileprivate var annotationManager
    @ObservationIgnored @Dependency(\.polylinePersistenceManager) fileprivate var polylineManager
    @ObservationIgnored @Dependency(\.locationTrackingManager) fileprivate var locationManager
    @ObservationIgnored @Dependency(\.toastManager) fileprivate var toastManager
    
    var currentMapStyle: MapStyle {
        switch appSettings.mapStyle {
        case .hybrid:
            return .satelliteStreets
        case .satellite:
            return .satellite
        case .standard:
            return .standard
        }
    }
    
    var distanceUnit: ScaleBarViewOptions.Units {
        switch appSettings.distanceUnit {
        case .imperial:
            return .imperial
        case .metric:
            return .metric
        }
    }
    
    var isSheetMaximized: Bool {
        selectedDetent == .tpLarge
    }
    
    var showTerrain: Bool {
        appSettings.isTerrainEnabled
    }
    
    var showContour: Bool {
        appSettings.isContourEnabled
    }
    
    init() {
        registerForLocationStatusUpdates()
        registerForLocationUpdates()
        
        if appSettings.isUserLocationActive {
            withViewportAnimation(.default) {
                cameraPosition = .followPuck(zoom: 10)
            }
        }
        
        featureLibraryCoordinator.onSearchFocusChanged = { [weak self] isFocused in
            if isFocused {
                self?.selectedDetent = .tpLarge
            } else {
                self?.selectedDetent = .tpMedium
            }
        }
        
        featureLibraryCoordinator.onSelection = { [weak self] feature in
            self?.handleNavigatorSelection(feature)
        }
        
        featureLibraryCoordinator.onSettingsPresented = { [weak self] in
            if self?.selectedDetent == .tpLarge {
                self?.shelvedPresentationDetent = self?.selectedDetent
                self?.selectedDetent = .tpSmall
            }
        }
        
        featureLibraryCoordinator.onSettingsDismissed = { [weak self] in
            if let detentBeforeSettigsPresented = self?.shelvedPresentationDetent {
                self?.selectedDetent = detentBeforeSettigsPresented
                self?.shelvedPresentationDetent = nil
            }
        }
        
        featureLibraryCoordinator.onNewFeatureCancellation = { [weak self] feature in
            self?.queueCancelAction(PendingCancelAction(action: feature))
        }
        
        featureLibraryCoordinator.onPolylineCreation = { [weak self] isTracked in
            if isTracked {
                self?.handle(.confirmTrackedPolyline)
            } else {
                self?.handle(.confirmPolyline)
            }
        }
    }
}

// MARK: - Functions
extension MapCoordinator {
    func handleMapTagSelection(_ tag: MapFeatureTag?, annotations: [AnnotationData], polylines: [PolylineData]) {
        // Only allow selection of another feature if we're not currently creating one
        // TODO: - Consider showing a toast so that if the user doesn't know that they are making a feature, they will alerted and it wont seem like the app is broken
        guard annotationManager.workingAnnotation == nil, polylineManager.workingPolyline == nil else { return }
        
        selectedMapFeature = switch tag {
            case .none: nil
            case .workingAnnotation: .workingAnnotation
            case .workingPolyline: .workingPolyline
            case .annotation: annotations.first(where: { $0.tag == tag }).map { .annotation($0) }
            case .polyline: polylines.first(where: { $0.tag == tag }).map { .polyline($0) }
        }
    }
    
    func handleNavigatorSelection(_ newSelection: ResolvedMapFeature?) {
        selectedMapFeature = newSelection
        
        if let newSelection {
            withViewportAnimation(.fly) {
                switch newSelection {
                case let .annotation(annotation):
                    cameraPosition = .camera(center: annotation.clCoordinate, zoom: 14)
                case let .polyline(polyline):
                    cameraPosition = .overview(geometry: Geometry.lineString(LineString(polyline.clCoordinates)), geometryPadding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                case .workingAnnotation:
                    if let workingAnnotation = annotationManager.workingAnnotation {
                        cameraPosition = .camera(center: workingAnnotation.clCoordinate, zoom: 14)
                    }
                case .workingPolyline:
                    if let workingPolyline = polylineManager.workingPolyline {
                        cameraPosition = .overview(geometry: Geometry.lineString(LineString(workingPolyline.clCoordinates)), geometryPadding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                    }
                }
            }
        }
    }
    
    func handleFeatureSelectionFromMap(_ newSelection: ResolvedMapFeature?) {
        selectedMapFeature = newSelection
    }
    
    func handleLocationUpdate() {
        guard polylineManager.isTrackingPolyline,
              let lastLocation = locationManager.lastLocation?.coordinate
        else { return }
        
        polylineManager.appendTrackedPolylineCoordinate(lastLocation)
    }
    
    func handleUserLocationStatusUpdate() {
        if appSettings.isUserLocationActive {
            withViewportAnimation(.fly) {
                cameraPosition = .followPuck(zoom: 10)
            }
        }
    }
    
    func handle(_ intent: MapButtonIntent) {
        switch intent {
        case .beginAnnotationCreation:
            assertionFailure("This case should be handled by the caller and redirected to handleAnnotationCreation(at:)")
        case .confirmAnnotation:
            do {
                try annotationManager.finalizeWorkingAnnotation()
                
                selectedMapFeature = nil
                selectedDetent = .tpSmall
            } catch {
                // TODO: - Send to some analytics service
                toastManager.commitFeatureCreationError(error)
            }
        case .cancelAnnotation:
            // Also, creating a polyline and creating an annotation should be mutually exclusive
            queueCancelAction(.annotation)
        case .undoAnnotation:
            annotationManager.undo()
        case .beginPolylineDrawing:
            if polylineManager.workingPolyline == nil {
                polylineManager.startNewWorkingPolyline()
                selectedMapFeature = .workingPolyline
            } else {
                handle(.cancelPolyline)
            }
        case .confirmPolyline:
            do {
                _ = try polylineManager.finalizeWorkingPolyline()
                
                selectedMapFeature = nil
                selectedDetent = .tpSmall
            } catch {
                // TODO: - Send to some analytics service
                toastManager.commitFeatureCreationError(error)
            }
        case .cancelPolyline:
            queueCancelAction(.polyline(isTracked: false))
        case .undoPolyline:
            polylineManager.undo()
        case .beginTracking:
            if polylineManager.workingPolyline == nil {
                polylineManager.startNewLocationTrackedPolyline(withUserCoordinate: locationManager.startTracking())
                selectedMapFeature = .workingPolyline
            } else {
                handle(.cancelTracking)
            }
        case .confirmTrackedPolyline:
            do {
                _ = try polylineManager.finalizeWorkingPolyline()
                
                locationManager.stopTracking()
            } catch let PolylineFinalizationError.tooFewCoordinates(required, have) {
                toastManager.addBreadForToasting(.polylineCreationError(.tooFewCoordinates(required: required, have: have)))
            } catch PolylineFinalizationError.emptyTitle {
                toastManager.addBreadForToasting(.polylineCreationError(.emptyTitle))
            } catch {
                toastManager.addBreadForToasting(.somethingWentWrong(.error(error)))
            }
        case .cancelTracking:
            queueCancelAction(.polyline(isTracked: true))
        case .showUserLocation:
            locationManager.showUserLocation()
        case .hideUserLocation:
            if polylineManager.isTrackingPolyline {
                queueCancelAction(.hideLocationWhileTracking)
            } else {
                locationManager.hideUserLocation()
            }
        }
    }
    
    func handle(_ intent: GroupedMapContentCoordinateIntent) {
        switch intent {
        case let .moveAnnotation(annotation, coordinate):
            annotation.coordinate = Coordinate(coordinate)
            
            do {
                try annotationManager.save()
            } catch {
                toastManager.addBreadForToasting(.somethingWentWrong(.error(error)))
            }
        case let .moveWorkingAnnotation(coordinate):
            annotationManager.changeWorkingAnnotationsCoordinate(to: Coordinate(coordinate))
        case let .moveWorkingPolyline(index, coordinate):
            polylineManager.moveWorkingPolylineCoordinate(at: index, to: coordinate)
        }
    }
    
    func handleFailedIntentConversion(for intent: GroupedMapContentIntent) {
        switch intent {
        case let .moveAnnotation(annotation, point):
            // TODO: - Send to some analytics service
            toastManager.addBreadForToasting(.somethingWentWrong(.message("Annotation movement was not possible for annotation with title: \(annotation.title).\n(\(point) could not be converted to a map coordinate")))
        case let .moveWorkingAnnotation(point):
            // TODO: - Send to some analytics service
            toastManager.addBreadForToasting(.somethingWentWrong(.message("Working annotation movement was not possible. (\(point) could not be converted to a map coordinate")))
        case let .moveWorkingPolyline(_, point):
            // TODO: - Send to some analytics service
            toastManager.addBreadForToasting(.somethingWentWrong(.message("Working polyline point movement was not possible. (\(point) could not be converted to a map coordinate")))
        }
    }
    
    func queueCancelAction(_ action: PendingCancelAction) {
        pendingCancelAction = action
        showCancelConfirmation = true
    }

    func confirmPendingCancel() {
        defer {
            showCancelConfirmation = false
            pendingCancelAction = nil
        }

        switch pendingCancelAction {
        case .annotation:
            annotationManager.clearWorkingAnnotationProgress()
            selectedMapFeature = nil
            selectedDetent = .tpSmall
        case .polyline(let isTracked):
            polylineManager.clearWorkingPolylineProgress()
            selectedMapFeature = nil
            selectedDetent = .tpSmall
            
            if isTracked {
                locationManager.stopTracking()
            }
        case .hideLocationWhileTracking:
            polylineManager.clearWorkingPolylineProgress()
            selectedMapFeature = nil
            selectedDetent = .tpSmall
            locationManager.stopTracking()
            locationManager.hideUserLocation()
        case nil:
            break
        }
    }

    func dismissPendingCancel() {
        showCancelConfirmation = false
        pendingCancelAction = nil
    }

    func handleAnnotationCreation(at coordinate: CLLocationCoordinate2D) {
        if annotationManager.workingAnnotation == nil {
            annotationManager.changeWorkingAnnotationsCoordinate(to: Coordinate(coordinate))
            selectedMapFeature = .workingAnnotation
        } else {
            handle(.cancelAnnotation)
        }
    }
    
    func handleFeatureChange(annotations: [AnnotationData]? = nil, polylines: [PolylineData]? = nil) {
        if let annotations {
            let annotationFeatures = annotations.map(\.feature)
            annotationFeatureCollection = FeatureCollection(features: annotationFeatures)
        }
        
        if let polylines {
            let polylineFeatures = polylines.map(\.feature)
            polylineFeatureCollection = FeatureCollection(features: polylineFeatures)
        }
    }
    
    func fitMapToFeatures() {
        guard !(annotationFeatureCollection.features.isEmpty && polylineFeatureCollection.features.isEmpty) else { return }
        
        cameraPosition = .overview(geometry: Geometry.geometryCollection(GeometryCollection(geometries: annotationFeatureCollection.features.compactMap(\.geometry) + polylineFeatureCollection.features.compactMap(\.geometry))), geometryPadding: EdgeInsets(top: 75, leading: 75, bottom: 75, trailing: 75), maxZoom: 14)
    }
    
    func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        guard polylineManager.isDrawingPolyline else { return }
        
        polylineManager.appendWorkingPolylineCoordinate(Coordinate(coordinate))
        selectedMapFeature = .workingPolyline
    }
    
    func handleInitialShowSheet() {
        if showSheet { return }
        showSheet = true
        
        if let trackingId = locationManager.checkForPendingTracks() {
            restoreTrackingSession(trackingId: trackingId)
        }
    }
}

extension MapCoordinator {
    private func registerForLocationStatusUpdates() {
        withObservationTracking {
            _ = appSettings.isUserLocationActive
        } onChange: {
            Task { @MainActor [weak self] in
                self?.handleUserLocationStatusUpdate()
                self?.registerForLocationStatusUpdates()
            }
        }
    }
    
    private func registerForLocationUpdates() {
        withObservationTracking {
            _ = locationManager.lastLocation
        } onChange: {
            Task { @MainActor [weak self] in
                self?.handleLocationUpdate()
                self?.registerForLocationUpdates()
            }
        }
    }
    
    private func restoreTrackingSession(trackingId: UUID) {
        let pendingLocations = locationManager.getPendingLocations(forTrackingId: trackingId)
        
        // TODO: - Alert user and ask if they want to continue tracking, save as is, or discard
        
        if !pendingLocations.isEmpty {
            polylineManager.startNewLocationTrackedPolyline()
            
            for location in pendingLocations {
                polylineManager.appendTrackedPolylineCoordinate(location)
            }
            
            // Clear the pending locations now that they've been restored
            locationManager.clearAllPendingLocations()
            
            // Continue tracking
            locationManager.startTracking()
            selectedMapFeature = .workingPolyline
        }
    }
}


// MARK: - Computed Properties
extension MapCoordinator {
    var annotationButtonState: AnnotationButtonState {
        AnnotationButtonState(isShowingOptions: annotationManager.isShowingOptions, canUndo: annotationManager.canUndo)
    }
    var polylineButtonState: PolylineButtonState {
        PolylineButtonState(isDrawing: polylineManager.isDrawingPolyline, isTracking: polylineManager.isTrackingPolyline, isShowingOptions: polylineManager.isShowingOptions, canUndo: polylineManager.canUndo)
    }
    var locationButtonState: LocationButtonState {
        LocationButtonState(isActive: appSettings.isUserLocationActive)
    }
    
    var annotationOverlayState: AnnotationOverlayState {
        AnnotationOverlayState(isShowingOptions: annotationManager.isShowingOptions, workingAnnotation: annotationManager.workingAnnotation)
    }
    var polylineOverlayState: PolylineOverlayState {
        PolylineOverlayState(isTracking: polylineManager.isTrackingPolyline, workingPolyline: polylineManager.workingPolyline)
    }
    var locationOverlayState: LocationOverlayState {
        LocationOverlayState(isActive: appSettings.isUserLocationActive)
    }
}
