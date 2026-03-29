import SwiftUI
import SwiftData
import MapboxMaps
import WarmToast
import Dependencies

func joinMarkerImage(with categoryImageName: String, baseColor: Color, categoryColor: Color) -> UIImage {
    let baseImage = UIImage(named: "teardrop")!
        .withTintColor(UIColor(baseColor), renderingMode: .alwaysOriginal)
    let overlayImage = UIImage(named: categoryImageName)!
        .withTintColor(UIColor(categoryColor), renderingMode: .alwaysOriginal)

    let size = baseImage.size
    let renderer = UIGraphicsImageRenderer(size: size)

    return renderer.image { _ in
        baseImage.draw(in: CGRect(origin: .zero, size: size))

        let overlayRect = CGRect(
            x: (size.width - overlayImage.size.width) / 2,
            y: (size.height - overlayImage.size.height) / 2 - 8,
            width: overlayImage.size.width,
            height: overlayImage.size.height
        )
        overlayImage.draw(in: overlayRect)
    }
}

struct AnnotationSnapshot: Equatable {
    let tag: MapFeatureTag
    let title: String
    let coordinate: CLLocationCoordinate2D
}

extension AnnotationSnapshot {
    init(_ annotation: AnnotationProvider) {
        self.tag = annotation.tag
        self.title = annotation.title
        self.coordinate = annotation.clCoordinate
    }
}

struct PolylineSnapshot: Equatable {
    let tag: MapFeatureTag
    let title: String
    let coordinates: [CLLocationCoordinate2D]
}

extension PolylineSnapshot {
    init(_ polyline: PolylineProvider) {
        self.tag = polyline.tag
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

// TODO: When creating a new annotation, the sheet should be set to medium and the map should move so that the annotation is in the middle of the visible map content. Same for polylines
struct DetailedMapView: View {
    @Dependency(\.toastManager) private var toastManager
    @State private var coordinator = MapCoordinator()
    
    @Query private var annotations: [AnnotationData]
    @Query private var polylines: [PolylineData]
    
    @Namespace private var nspace
    @ScaledMetric(relativeTo: .title) private var buttonSize = 52
    
    @Binding private var showSheet: Bool
    
    private let detents: Set<PresentationDetent> = .defaultMapSheetDetents

    private func ornamentOptions(height: CGFloat) -> OrnamentOptions {
        let smallDetentHeight: CGFloat =
        if UIDevice.current.userInterfaceIdiom == .pad {
            10
        } else {
            if #available(iOS 26, *) {
                PresentationDetent.smallDetentHeight
            } else {
                height / 6.5
            }
        }
        
        return OrnamentOptions(
            scaleBar: ScaleBarViewOptions(position: .topLeft, margins: CGPoint(x: 10, y: 0), visibility: .visible, units: coordinator.distanceUnit),
            compass: CompassViewOptions(position: .topLeft, margins: CGPoint(x: 10, y: 30), image: nil, visibility: .visible),
            logo: LogoViewOptions(position: .bottomLeft, margins: CGPoint(x: 10, y: smallDetentHeight)),
            attributionButton: AttributionButtonOptions(position: .bottomRight, margins: CGPoint(x: 10, y: smallDetentHeight), tintColor: nil)
        )
    }
    
    private var selectedTag: Binding<MapFeatureTag?> {
        Binding {
            coordinator.selectedMapFeature?.tag
        } set: { tag in
            coordinator.handleMapTagSelection(tag, annotations: annotations, polylines: polylines)
        }
    }
    
    init(showSheet: Binding<Bool>) {
        self._showSheet = showSheet
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            MapReader { proxy in
                Map(viewport: $coordinator.cameraPosition) {
                    GroupedMapStyle(show3DTerrain: coordinator.showTerrain, showContor: coordinator.showContour, usesMetric: coordinator.distanceUnit == .metric)
                    
                    GroupedMapContent(
                        annotationState: coordinator.annotationOverlayState,
                        polylineState: coordinator.polylineOverlayState,
                        locationState: coordinator.locationOverlayState,
                        selection: coordinator.selectedMapFeature,
                        annotationFeatureCollection: coordinator.annotationFeatureCollection,
                        polylineFeatureCollection: coordinator.polylineFeatureCollection
                    ) { intent in
                        guard let coordinateIntent = intent.toCoordinateIntent(proxy: proxy, annotations: annotations, polylines: polylines) else {
                            coordinator.handleFailedIntentConversion(for: intent)
                            return
                        }
                        
                        coordinator.handle(coordinateIntent)
                    } onSelection: { tag in
                        if [.workingAnnotation, .workingPolyline].contains(coordinator.selectedMapFeature) { return false }
                        
                        switch tag {
                        case .annotation(let id):
                            guard let annotation = annotations.first(where: { $0.id == id }) else {
                                toastManager.addBreadForToasting(.somethingWentWrong(.message("Unable to find map annotation with tag \(tag)")))
                                return false
                            }
                            coordinator.handleFeatureSelectionFromMap(.annotation(annotation))
                        case .polyline(let id):
                            guard let polyline = polylines.first(where: { $0.id == id }) else {
                                toastManager.addBreadForToasting(.somethingWentWrong(.message("Unable to find map polyline with tag \(tag)")))
                                return false
                            }
                            coordinator.handleFeatureSelectionFromMap(.polyline(polyline))
                        case .workingAnnotation:
                            coordinator.handleFeatureSelectionFromMap(.workingAnnotation)
                        case .workingPolyline:
                            coordinator.handleFeatureSelectionFromMap(.workingPolyline)
                        }
                        
                        return true
                    }
                }
                .onStyleLoaded { _ in
                    // TODO: - Better error handling
                    guard let map = proxy.map else { fatalError("No map") }
                    guard !coordinator.styleWasInitiallyLoaded else { return }
                    
                    do {
                        try map.addImage(joinMarkerImage(with: "star", baseColor: .orange, categoryColor: .white), id: "marker", sdf: false)
                    } catch {
                        fatalError("error: \(error)")
                    }
                    
                    coordinator.handleFeatureChange(annotations: annotations, polylines: polylines)
                    coordinator.fitMapToFeatures()
                }
                .ornamentOptions(ornamentOptions(height: frame.height))
                // TODO: - Don't force unwrap and allow user to select a style from a set of like 3 or something
                // Also, paths are drawn underneath 3d models and thus are sometimes obscured. Something to look into
                .mapStyle(coordinator.currentMapStyle)//MapboxMaps.MapStyle(uri: StyleURI(url: URL(string: "mapbox://styles/mazjap/cmmvaacbn00hh01su1kzc652h")!)!))
                .onTapGesture { location in
                    guard let coordinate = proxy.map?.coordinate(for: location) else { return }
                    coordinator.handleMapTap(at: coordinate)
                }
                // TODO: - Test how bad this is and look into more efficient ways than recreating the entire feature collection if needed
                .onChange(of: annotations.map(AnnotationSnapshot.init)) {
                    coordinator.handleFeatureChange(annotations: annotations)
                }
                .onChange(of: polylines.map(PolylineSnapshot.init)) {
                    coordinator.handleFeatureChange(polylines: polylines)
                }
                .ignoresSafeArea()
                .overlay(alignment: .topTrailing) {
                    MapControlButtons(
                        annotationState: coordinator.annotationButtonState,
                        polylineState: coordinator.polylineButtonState,
                        locationState: coordinator.locationButtonState,
                        isHidden: coordinator.isSheetMaximized,
                        nspace: nspace,
                        buttonSize: buttonSize
                    ) { intent in
                        if case .beginAnnotationCreation = intent {
                            let midPoint = CGPoint(x: frame.midX, y: frame.midY)
                            guard let map = proxy.map else {
                                // TODO: - Send to some analytics service
                                toastManager.addBreadForToasting(.somethingWentWrong(.message("Coordinate conversion did not occur because the map was not available")))
                                return
                            }
                            
                            let coordinate = map.coordinate(for: midPoint)
                            
                            coordinator.handleAnnotationCreation(at: coordinate)
                        } else {
                            coordinator.handle(intent)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            FeatureLibrary(
                coordinator: coordinator.featureLibraryCoordinator,
                selection: coordinator.selectedMapFeature,
                annotations: annotations,
                polylines: polylines
            )
            .presentationDetents(detents, selection: $coordinator.selectedDetent)
            .presentationBackgroundInteraction(.enabled(upThrough: .tpMedium))
            .interactiveDismissDisabled()
        }
        .preheatToaster(
            withLoaf: Bindable(toastManager).reasons,
            options: .toasterStrudel(type: .error)
        ) { bread in
            ToastView(bread: bread)
        }
    }
}

#Preview {
    @Dependency(\.modelContainer) var modelContainer
    
    DetailedMapView(showSheet: .constant(true))
        .modelContainer(modelContainer)
}
