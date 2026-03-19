import SwiftUI
import SwiftData
import MapboxMaps
import WarmToast
import Dependencies

@MainActor
func joinMarkerImage(with categoryImageName: String, baseColor: Color, categoryColor: Color) -> UIImage {
    ImageRenderer(content: {
        Image(.teardrop)
            .foregroundStyle(baseColor)
            .overlay {
                Image(categoryImageName)
                    .renderingMode(.template)
                    .foregroundStyle(categoryColor)
                    .offset(x: 0, y: -8)
            }
    }()).uiImage!
}

struct AnnotationMapDisplayDetails: Equatable {
    var title: String
    var coordinate: CLLocationCoordinate2D
}

extension AnnotationMapDisplayDetails {
    init(_ annotation: AnnotationProvider) {
        self.title = annotation.title
        self.coordinate = annotation.clCoordinate
    }
}

struct PolylineMapDisplayDetails: Equatable {
    var title: String
    var coordinates: [CLLocationCoordinate2D]
}

extension PolylineMapDisplayDetails {
    init(_ polyline: PolylineProvider) {
        self.title = polyline.title
        self.coordinates = polyline.clCoordinates
    }
}

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
    
    @State private var cameraPosition: Viewport = .idle
    @State private var selectedMapItemTag: MapFeatureTag?
    @State private var presentedMapFeature: MapFeatureToPresent?
    @State private var selectedDetent = PresentationDetent.small
    // TODO: - Handle name changes as well
    @State private var annotationFeatureCollection: FeatureCollection?
    @State private var polylineFeatureCollection: FeatureCollection?
    
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
                    if let annotationFeatureCollection {
                        GeoJSONSource(id: "annotation-source")
                            .data(.featureCollection(annotationFeatureCollection))
                    }
                    
                    if let polylineFeatureCollection {
                        GeoJSONSource(id: "polyline-source")
                            .data(.featureCollection(polylineFeatureCollection))
                    }
                    
                    if locationManager.isUserLocationActive {
                        // TODO: - Style puck to my liking or use Puck3D!
                        Puck2D()
                    }
                    
                    annotationViews(proxy: proxy)
                    
                    polylineViews(proxy: proxy)
                    
                    inProgressPolyline(proxy: proxy)
                    
                    inProgressPin(proxy: proxy)
                }
                .onStyleLoaded { _ in
                    // TODO: - Better error handling
                    guard let map = proxy.map else { fatalError("No map") }
                    
                    do {
                        try map.addImage(joinMarkerImage(with: "star", baseColor: .orange, categoryColor: .white), id: "marker", sdf: false)
                    } catch {
                        fatalError("error: \(error)")
                    }
                    
                    let annotationFeatures = annotations.map(\.feature)
                    let polylineFeatures = polylines.map(\.feature)
                    annotationFeatureCollection = FeatureCollection(features: annotationFeatures)
                    polylineFeatureCollection = FeatureCollection(features: polylineFeatures)
                    
                    cameraPosition = .overview(geometry: Geometry.geometryCollection(GeometryCollection(geometries: annotationFeatures.compactMap(\.geometry) + polylineFeatures.compactMap(\.geometry))), geometryPadding: EdgeInsets(top: 75, leading: 75, bottom: 75, trailing: 75), maxZoom: 14)
                }
                .ornamentOptions(ornamentOptions(height: frame.height))
                // TODO: - Don't force unwrap and allow user to select a style from a set of like 3 or something
                // Also, paths are drawn underneath 3d models and thus are sometimes obscured. Something to look into
                .mapStyle(MapboxMaps.MapStyle(uri: StyleURI(url: URL(string: "mapbox://styles/mazjap/cmmvaacbn00hh01su1kzc652h")!)!))
                .onTapGesture { location in
                    guard polylineManager.isDrawingPolyline else { return }
                    guard let coordinate = proxy.map?.coordinate(for: location) else { return }
                    
                    polylineManager.appendWorkingPolylineCoordinate(Coordinate(coordinate))
                    
                    // If this is the first point, show the options UI
                    if polylineManager.workingPolyline?.coordinates.count == 1 {
                        selectedMapItemTag = .newFeature
                    }
                }
                // TODO: - Test how bad this is and look into more efficient ways than recreating the entire feature collection if needed
                .onChange(of: annotations.map(AnnotationMapDisplayDetails.init)) {
                    annotationFeatureCollection = FeatureCollection(features: annotations.map(\.feature))
                }
                .onChange(of: polylines.map(PolylineMapDisplayDetails.init)) {
                    polylineFeatureCollection = FeatureCollection(features: polylines.map(\.feature))
                }
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
        // TODO: - Clustering
        SymbolLayer(id: "marker-layer", source: "annotation-source")
            .iconImage("marker")
            .textFont(["Open Sans Bold"])
            .iconAnchor(.bottom)
            .textSize(12)
            .textColor(.white)
            .textAnchor(.top)
            .textHaloWidth(2)
            .textHaloColor(.black)
            .textHaloBlur(1)
            .textOffset(x: 0, y: 0.25)
            .iconAllowOverlap(true)
            .textOptional(true)
            .textField(Exp(.get) { "title" })
        
        TapInteraction(.layer("marker-layer")) { feature, context in
            if selectedMapItemTag == .newFeature { return true }
            
            guard let id = feature.id?.id,
                  let tag = MapFeatureTag(rawValue: id)
            else {
                return false
            }
            
            selectedMapItemTag = tag
            return true
        }
        
        if let selectedMapItemTag,
           case .annotation = selectedMapItemTag,
           let annotation = annotations.first(where: { $0.tag == selectedMapItemTag }) {
            AnnotationMapOverlay(annotation: annotation, movementEnabled: true, shouldJiggle: false, foregroundColor: .orange) { newPosition in
                guard let newCoordinate = proxy.map?.coordinate(for: newPosition) else {
                    // TODO: - Send to some analytics service
                    toastManager.addBreadForToasting(.somethingWentWrong(.message("Annotation movement was not possible. (\(newPosition) could not be converted to a map coordinate")))
                    return
                }
                
                annotation.coordinate = Coordinate(newCoordinate)
                
                do {
                    try annotationManager.save()
                } catch {
                    // TODO: Do somehthing other than swallowing
                    print(error)
                }
            }
        }
    }
    
    @MapContentBuilder
    private func polylineViews(proxy: MapProxy) -> some MapContent {
        LineLayer(id: "line-layer", source: "polyline-source")
            .lineWidth(5)
            .lineJoin(.round)
            .lineDashArray([3, 2])
            .lineColor(Exp(.switchCase) {
                Exp(.boolean) { Exp(.get) { "isLocationTracked" } }
                Exp(.toColor) { "#FF8D28" }
                Exp(.toColor) { "#FE383C" }
            })
        
        // TODO: - Look into laying out text on top of path
        
        TapInteraction(.layer("line-layer")) { feature, context in
            if selectedMapItemTag == .newFeature { return true }
            
            guard let id = feature.id?.id,
                  let tag = MapFeatureTag(rawValue: id)
            else {
                return false
            }
            
            selectedMapItemTag = tag
            return true
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
            PolylineAnnotation(id: workingPolyline.tag.id, lineCoordinates: workingPolyline.clCoordinates, isSelected: false, isDraggable: false)
                .lineColor(UIColor(polylineManager.isTrackingPolyline ? .purple : .blue))
                .lineWidth(3)
                .lineJoin(.round)
            
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
