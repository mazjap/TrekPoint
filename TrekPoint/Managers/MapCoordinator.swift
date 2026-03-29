import SwiftUI
import MapboxMaps
import Dependencies
import Combine

@Observable
@MainActor
class MapCoordinator {
    var cameraPosition: Viewport = .idle
    var selectedMapFeature: ResolvedMapFeature?
    var selectedDetent: PresentationDetent = .tpSmall
    var featureLibraryCoordinator = FeatureLibraryCoordinator()
    
    @ObservationIgnored private var shelvedPresentationDetent: PresentationDetent?
    @ObservationIgnored private var subscription: AnyCancellable?
    
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
    
    init() {
        subscription = NotificationCenter.default.publisher(for: .restoreTrackingSession)
            .sink { [weak self] notification in
                Task { @MainActor [weak self] in
                    if let trackingId = notification.userInfo?["trackingID"] as? UUID {
                        self?.restoreTrackingSession(trackingId: trackingId)
                    }
                }
            }
        
        registerForLocationStatusUpdates()
        registerForLocationUpdates()
        
        if locationManager.isUserLocationActive {
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
        if locationManager.isUserLocationActive {
            withViewportAnimation(.fly) {
                cameraPosition = .followPuck(zoom: 10)
            }
        }
    }
    
    func handle(_ intent: MapButtonIntent) {
        switch intent {
        case .beginAnnotationCreation:
            fatalError("This case should be handled by the caller and redirected to handleAnnotationCreation(at:)")
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
            // TODO: - Show an alert to confirm that the user wants to clear progress (same with working polyline)
            // Also, creating a polyline and creating an annotation should be mutually exclusive
            annotationManager.clearWorkingAnnotationProgress()
            selectedMapFeature = nil
            selectedDetent = .tpSmall
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
            polylineManager.clearWorkingPolylineProgress()
            selectedMapFeature = nil
            selectedDetent = .tpSmall
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
            polylineManager.clearWorkingPolylineProgress()
            selectedMapFeature = nil
            selectedDetent = .tpSmall
            locationManager.stopTracking()
        case .showUserLocation:
            locationManager.showUserLocation()
        case .hideUserLocation:
            // TODO: - Also cancel user-tracked working polyline and/or alert user that turning off location will stop the in-progress polyline
            locationManager.hideUserLocation()
        }
    }
    
    func handle(_ intent: GroupedMapContentCoordinateIntent) {
        switch intent {
        case let .moveAnnotation(annotation, coordinate):
            annotation.coordinate = Coordinate(coordinate)
            
            do {
                try annotationManager.save()
            } catch {
                // TODO: Do somehthing other than swallowing
                print(error)
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
    
    func handleAnnotationCreation(at coordinate: CLLocationCoordinate2D) {
        if annotationManager.workingAnnotation == nil {
            annotationManager.changeWorkingAnnotationsCoordinate(to: Coordinate(coordinate))
            selectedMapFeature = .workingAnnotation
        } else {
            handle(.cancelAnnotation)
        }
    }
    
    func handleMapTap(at coordinate: CLLocationCoordinate2D) {
        guard polylineManager.isDrawingPolyline else { return }
        
        polylineManager.appendWorkingPolylineCoordinate(Coordinate(coordinate))
        selectedMapFeature = .workingPolyline
    }
    
    func restoreTrackingSession(trackingId: UUID) {
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

extension MapCoordinator {
    private func registerForLocationStatusUpdates() {
        withObservationTracking {
            _ = locationManager.isUserLocationActive
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
        LocationButtonState(isActive: locationManager.isUserLocationActive)
    }
    
    var annotationOverlayState: AnnotationOverlayState {
        AnnotationOverlayState(isShowingOptions: annotationManager.isShowingOptions, workingAnnotation: annotationManager.workingAnnotation)
    }
    var polylineOverlayState: PolylineOverlayState {
        PolylineOverlayState(isTracking: polylineManager.isTrackingPolyline, workingPolyline: polylineManager.workingPolyline)
    }
    var locationOverlayState: LocationOverlayState {
        LocationOverlayState(isActive: locationManager.isUserLocationActive)
    }
}
