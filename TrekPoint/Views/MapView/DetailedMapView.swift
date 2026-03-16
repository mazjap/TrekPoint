import SwiftUI
import SwiftData
import MapboxMaps
import WarmToast
import Dependencies

// Tasks:
// - [x] Get user's location working
// - [x] Get DraggablePin to relocate correctly on drag gesture
//    - [x] (it's getting set to slightly above the drop location)
// - [x] Confirm newly created annotation
//    - [x] Add ~~tap gesture~~ button to confirm location
//    - [x] Create AnnotationData for given coordinate and clear newAnnotationLocation
// - [x] Add polyline support
//    - [x] "Following user location" type polyline
//      - [x] While using the app
//      - [x] While app is in background
//    - [x] "Tap to draw" type polyline
// - [x] Better (or any) error handling
//    - [x] Add red border to annotation title when user presses confirm and title is empty
//    - [x] Add some sort of toast alert system or package
// - [ ] Refactor architecture to decouple views and business logic


// - Stretch Goals:
//   - [ ] Cache tiles for offline use
//   - [ ] Settings page:
//     - [ ] Map style (standard, satellite, hybrid, topographic)
//     - [ ] Annotation style (pin color, icon type)
//     - [ ] Polyline style (color, width, pattern)
//     - [ ] Distance units (miles/kilometers)
//     - [ ] Coordinate format (decimal, DMS)
//     - [ ] GPS tracking sensitivity/battery optimization
//     - [ ] Map overlay buttons visibility (Compass and scale)
//     - [ ] Dark/Light mode or system
//     - [ ] Background tracking permissions
//     - [ ] Offline mode settings/management
//   - [ ] Search & sort functionality for annotations and polylines
//   - [ ] Photo/Video attachments for annotations (for documenting
//   finds)
//   - [ ] iCloud sync for cross-device usage
//   - [ ] Categorized annotations (antler finds, trail cameras, bedding
//   areas, etc.)
// -------------------------------Unlikely-------------------------------
//   - [ ] Basic stats dashboard (miles walked, stairs climed, finds
//   this season, etc.)
//   - [ ] Use ActivityKit to show a Live Activity on the lockscreen when
//   path tracking
//   - [ ] Import/export data (GPX format for compatibility)
//   - [ ] Area calculation tool (measure acreage of drawn polygons)
//   - [ ] Share maps/locations via standard iOS share sheet
// -----------------------------Very unlikely----------------------------
//   - [ ] Elevation data display (Vapor Server with USGS DEM data)
//   - [ ] Weather integration (WeatherKit?)
//   - [ ] Public land boundaries overlay (Vapor Server with PADUS 4.0?)

struct DetailedMapView: View {
    @Dependency(\.locationTrackingManager) private var locationManager
    @Dependency(\.annotationPersistenceManager) private var annotationManager
    @Dependency(\.polylinePersistenceManager) private var polylineManager
    @Dependency(\.toastManager) private var toastManager: ToastManager
    
    @Query private var annotations: [AnnotationData]
    @Query private var polylines: [PolylineData]
    
    @Namespace private var nspace
    @ScaledMetric(relativeTo: .title) private var buttonSize = 52
    
    @State private var cameraPosition: Viewport = .styleDefault
    @State private var selectedMapItemTag: MapFeatureTag?
    @State private var presentedMapFeature: MapFeatureToPresent?
    @State private var selectedDetent = PresentationDetent.small
    
    @Binding private var showSheet: Bool
    
    private let detents: Set<PresentationDetent> = .defaultMapSheetDetents
    
    private func ornamentOptions(height: CGFloat) -> OrnamentOptions {
        let smallDetentHeight: CGFloat =
        if UIDevice.current.userInterfaceIdiom == .pad {
            10
        } else {
            height / 6.5
        }
        
        return OrnamentOptions(
            scaleBar: ScaleBarViewOptions(position: .topLeft, margins: CGPoint(x: 10, y: 0), visibility: .visible, useMetricUnits: false, units: .imperial),
            compass: CompassViewOptions(position: .topLeft, margins: CGPoint(x: 10, y: 30), image: nil, visibility: .visible),
            logo: LogoViewOptions(position: .bottomLeft, margins: CGPoint(x: 10, y: smallDetentHeight)),
            attributionButton: AttributionButtonOptions(position: .bottomRight, margins: CGPoint(x: 10, y: smallDetentHeight), tintColor: nil)
        )
    }
    
    init(showSheet: Binding<Bool>) {
        self._showSheet = showSheet
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            MapReader { proxy in
                Map(viewport: $cameraPosition) {
                    StyleProjection(name: .globe)
                    
                    RasterDemSource(id: "mapbox-dem")
                        .url("mapbox://mapbox.mapbox-terrain-dem-v1")
                        .maxzoom(14.0)
                    
                    Terrain(sourceId: "mapbox-dem")
                        .exaggeration(1.25)
                    
                    if locationManager.isUserLocationActive {
                        Puck2D()
                    }
                    
                    annotationViews(proxy: proxy)
                    
                    polylineViews(proxy: proxy)
                    
                    inProgressPolyline(proxy: proxy)
                    
                    inProgressPin(proxy: proxy)
                }
                .ornamentOptions(ornamentOptions(height: frame.height))
                .mapStyle(.standardSatellite(lightPreset: .dusk))
                .ignoresSafeArea()
                .overlay(alignment: .topTrailing) {
                    MapControlButtons(selectedMapItemTag: $selectedMapItemTag, selectedDetent: $selectedDetent, proxy: proxy, frame: frame, nspace: nspace, buttonSize: buttonSize)
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            MapFeatureNavigator(
                selection: $presentedMapFeature,
                annotations: annotations,
                polylines: polylines
            ) { newSelection in
                annotationManager.clearWorkingAnnotationProgress()

                if let newSelection {
                    selectedMapItemTag = newSelection.tag
                    
                    withViewportAnimation(.fly) {
                        switch newSelection {
                        case let .annotation(annotation):
                            cameraPosition = .camera(center: annotation.clCoordinate, zoom: 14)
                        case let .polyline(polyline):
                            cameraPosition = .overview(geometry: Geometry.lineString(LineString(polyline.clCoordinates)), geometryPadding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                        }
                    }
                } else {
                    selectedMapItemTag = nil
                }
            }
            .presentationDetents(detents, selection: $selectedDetent)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled()
        }
        .preheatToaster(
            withLoaf: Bindable(toastManager).reasons,
            options: .toasterStrudel(type: .error)
        ) { bread in
            ToastView(bread: bread)
        }
        .onChange(of: selectedMapItemTag) {
            switch selectedMapItemTag {
            case let .annotation(id):
                if let annotation = annotations.first(where: { id == $0.id }) {
                    presentedMapFeature = .annotation(annotation)
                } else {
                    // TODO: - Send to some analytics service
                    toastManager.addBreadForToasting(.somethingWentWrong(.message("Presentation of annotation with id: \(id) was requested, but no such map feature exists")))
                }
            case let .polyline(id):
                if let polyline = polylines.first(where: { id == $0.id }) {
                    presentedMapFeature = .polyline(polyline)
                } else {
                    // TODO: - Send to some analytics service
                    toastManager.addBreadForToasting(.somethingWentWrong(.message("Presentation of polyline with id: \(id) was requested, but no such map feature exists")))
                }
            case .newFeature:
                if annotationManager.workingAnnotation != nil {
                    presentedMapFeature = .workingAnnotation
                } else if polylineManager.workingPolyline != nil {
                    presentedMapFeature = .workingPolyline
                } else {
                    // TODO: - Send to some analytics service
                    toastManager.addBreadForToasting(.somethingWentWrong(.message("Presentation of the currently working feature (either annotation or polyline) was requested, but none exist")))
                }
            case .none:
                break
            }
        }
        .onChange(of: locationManager.isUserLocationActive) {
            if locationManager.isUserLocationActive {
                withViewportAnimation(.fly) {
                    cameraPosition = .followPuck(zoom: 10)
                }
            }
        }
        .onChange(of: locationManager.lastLocation) {
            guard polylineManager.isTrackingPolyline,
                  let lastLocation = locationManager.lastLocation?.coordinate
            else { return }
            
            polylineManager.appendTrackedPolylineCoordinate(lastLocation)
            print("New coordinate: \(lastLocation)")
        }
        .onChange(of: showSheet) {
            guard !showSheet else { return }
            
            Task {
                try await Task.sleep(for: .seconds(0.01))
                showSheet = true
            }
        }
        .onChange(of: polylineManager.workingPolyline?.isLocationTracked) { wasLocationTracked, _ in
            if wasLocationTracked ?? false {
                locationManager.stopTracking()
            }
        }
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: .restoreTrackingSession,
                object: nil,
                queue: .main
            ) { notification in
                if let trackingId = notification.userInfo?["trackingID"] as? UUID {
                    // Restore the tracking session
                    self.restoreTrackingSession(trackingId: trackingId)
                }
            }
            
            if locationManager.isUserLocationActive {
                withViewportAnimation(.fly) {
                    cameraPosition = .followPuck(zoom: 10)
                }
            }
        }
    }
    
    @MapContentBuilder
    private func annotationViews(proxy: MapProxy) -> some MapContent {
        ForEvery(annotations) { annotation in
            AnnotationMapOverlay(annotation: annotation, movementEnabled: true, shouldJiggle: false, foregroundColor: .orange) { newPosition in
                guard let newCoordinate = proxy.map?.coordinate(for: newPosition) else {
                    // TODO: - Send to some analytics service
                    toastManager.addBreadForToasting(.somethingWentWrong(.message("Annotation movement was not possible. (\(newPosition) could not be converted to a map coordinate")))
                    return
                }
                
                annotation.coordinate = Coordinate(newCoordinate)
            }
        }
    }
    
    @MapContentBuilder
    private func polylineViews(proxy: MapProxy) -> some MapContent {
        ForEvery(polylines) { polyline in
            PolylineMapOverlay(polyline: polyline, strokeColor: polyline.isLocationTracked ? .orange : .red)
        }
    }
    
    @MapContentBuilder
    private func inProgressPin(proxy: MapProxy) -> some MapContent {
        if let newAnnotationLocation = annotationManager.workingAnnotation {
            AnnotationMapOverlay(
                annotation: newAnnotationLocation,
                shouldJiggle: annotationManager.isShowingOptions,
                foregroundColor: .orange,
                fillColor: .blue
            ) { newPosition in
                guard let newCoordinate = proxy.map?.coordinate(for: newPosition) else {
                    // TODO: - Send to some analytics service
                    toastManager.addBreadForToasting(.somethingWentWrong(.message("Working annotation movement was not possible. (\(newPosition) could not be converted to a map coordinate")))
                    return
                }
                
                annotationManager.changeWorkingAnnotationsCoordinate(to: Coordinate(newCoordinate))
            }
        }
    }
    
    @MapContentBuilder
    private func inProgressPolyline(proxy: MapProxy) -> some MapContent {
        if let workingPolyline = polylineManager.workingPolyline, !workingPolyline.coordinates.isEmpty {
            PolylineMapOverlay(
                polyline: workingPolyline,
                strokeColor: polylineManager.isTrackingPolyline ? .purple : .blue
            )
            
            // Add markers for each point
            ForEvery(Array(workingPolyline.coordinates.enumerated()), id: \.1.id) { index, coordinate in
                MapViewAnnotation(coordinate: CLLocationCoordinate2D(coordinate)) {
                    DraggablePolylinePoint(
                        movementEnabled: !workingPolyline.isLocationTracked,
                        fillColor: polylineManager.isTrackingPolyline ? .purple : .blue
                    ) { newPosition in
                        guard let newCoordinate = proxy.map?.coordinate(for: newPosition) else {
                            // TODO: - Send to some analytics service
                            toastManager.addBreadForToasting(.somethingWentWrong(.message("Working polyline point movement was not possible. (\(newPosition) could not be converted to a map coordinate")))
                            return
                        }
                        
                        polylineManager.moveWorkingPolylineCoordinate(at: index, to: newCoordinate)
                    }
                }
            }
        }
    }
    
    private func restoreTrackingSession(trackingId: UUID) {
        let pendingLocations = locationManager.getPendingLocations(forTrackingId: trackingId)
        
        // Create a new polyline with these locations
        if !pendingLocations.isEmpty {
            // Start a new tracked polyline
            polylineManager.startNewLocationTrackedPolyline()
            
            // Add all the pending locations
            for location in pendingLocations {
                polylineManager.appendTrackedPolylineCoordinate(location)
            }
            
            // Clear the pending locations now that we've restored them
            locationManager.clearPendingLocations(for: trackingId)
            
            // Continue tracking
            let _ = locationManager.startTracking()
            selectedMapItemTag = .newFeature
        }
    }
}

#Preview {
    @Dependency(\.modelContainer) var modelContainer 
    
    DetailedMapView(showSheet: .constant(true))
        .modelContainer(modelContainer)
}
