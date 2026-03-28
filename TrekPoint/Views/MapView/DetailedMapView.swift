import SwiftUI
import SwiftData
import MapKit
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
                Map(position: $coordinator.cameraPosition, bounds: MapCameraBounds(minimumDistance: 0, maximumDistance: .infinity), selection: selectedTag, scope: nspace) {
                    GroupedMapContent(
                        annotationState: coordinator.annotationOverlayState,
                        polylineState: coordinator.polylineOverlayState,
                        locationState: coordinator.locationOverlayState,
                        annotations: annotations,
                        polylines: polylines
                    ) { intent in
                        guard let coordinateIntent = intent.toCoordinateIntent(proxy: proxy) else {
                            coordinator.handleFailedIntentConversion(for: intent)
                            return
                        }
                        
                        coordinator.handle(coordinateIntent)
                    }
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .mapControlVisibility(.hidden)
                .onTapGesture { location in
                    guard let coordinate = proxy.convert(
                        location,
                        from: .local
                    ) else {
                        return
                    }
                    
                    coordinator.handleMapTap(at: coordinate)
                }
                .overlay(alignment: .topTrailing) {
                    MapControlButtons(
                        annotationState: coordinator.annotationButtonState,
                        polylineState: coordinator.polylineButtonState,
                        locationState: coordinator.locationButtonState,
                        selectedDetent: coordinator.selectedDetent,
                        proxy: proxy,
                        nspace: nspace,
                        buttonSize: buttonSize
                    ) { intent in
                        if case .beginAnnotationCreation = intent {
                            let midPoint = CGPoint(x: frame.midX, y: frame.midY)
                            guard let coordinate = proxy.convert(midPoint, from: .global) else {
                                // TODO: - Send to some analytics service
                                toastManager.addBreadForToasting(.somethingWentWrong(.message("Annotation creation was not possible. (\(midPoint) could not be converted to a map coordinate")))
                                
                                return
                            }
                            
                            coordinator.handleAnnotationCreation(at: coordinate)
                        } else {
                            coordinator.handle(intent)
                        }
                    }
                }
            }
            .mapScope(nspace)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: PresentationDetent.smallDetentHeight)
            }
        }
        .sheet(isPresented: $showSheet) {
            FeatureLibrary(
                coordinator: coordinator.featureLibraryCoordinator,
                selection: coordinator.selectedMapFeature,
                annotations: annotations,
                polylines: polylines
            ) { newSelection in
                coordinator.handleNavigatorSelection(newSelection)
            }
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
