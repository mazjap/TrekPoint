import SwiftUI
import SwiftData
import MapKit

// Tasks:
// - [x] Get user's location working
// - [x] Get DraggablePin to relocate correctly on drag gesture
//    - [x] (it's getting set to slightly above the drop location)
// - [x] Confirm newly created annotation
//    - [x] Add ~~tap gesture~~ button to confirm location
//    - [x] Create AnnotationData for given coordinate and clear newAnnotationLocation
// - [ ] Add polyline support
//    - [ ] "Following user location" type polyline
//    - [ ] "Tap to draw" type polyline
// - [ ] Better (or any) error handling
//    - [ ] Add red border to annotation title when user presses confirm and title is empty
//    - [ ] Add some sort of toast alert system or package
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
//   - [ ] Import/export data (GPX format for compatibility)
//   - [ ] Area calculation tool (measure acreage of drawn polygons)
//   - [ ] Share maps/locations via standard iOS share sheet
// -----------------------------Very unlikely----------------------------
//   - [ ] Elevation data display
//   - [ ] Weather integration
//   - [ ] Public land boundaries overlay

struct DetailedMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var annotations: [AnnotationData]
    @Query private var polylines: [PolylineData]
    
    @Namespace private var nspace
    
    @AppStorage("is_user_location_active") private var showUserLocation: Bool = false
    
    @State private var newAnnotation = NewAnnotationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var cameraTransitionTrigger: CameraTrigger?
    @State private var selectedMapItemTag: MapFeatureTag?
    @State private var presentedMapFeature: MapFeatureToPresent?
    
    @State private var selectedDetent = PresentationDetent.small
    
    @ScaledMetric(relativeTo: .title) private var buttonSize = 52
    
    static private let locationManager = CLLocationManager()
    private let detents: Set<PresentationDetent> = .defaultMapSheetDetents
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            MapReader { proxy in
                Map(position: $cameraPosition, selection: $selectedMapItemTag, scope: nspace) {
                    if showUserLocation {
                        UserAnnotation()
                    }
                    
                    annotationViews(proxy: proxy)
                    
                    polylineViews(proxy: proxy)
                    
                    inProgressPin(proxy: proxy)
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .mapControlVisibility(.hidden)
                .mapCameraKeyframeAnimator(trigger: cameraTransitionTrigger) { camera in
                    KeyframeTrack(\MapCamera.centerCoordinate) {
                        let coordinate: CLLocationCoordinate2D = {
                            switch cameraTransitionTrigger {
                            case let .geometry(.annotation(coord)):
                                return coord
                            case let .geometry(.polyline(coords)):
                                // Create an MKMapRect that encompasses all coordinates
                                let center = MKMapRect(coordinates: coords).center
                                
                                // Get the center coordinate of the map rect
                                return CLLocationCoordinate2D(latitude: center.coordinate.latitude, longitude: center.coordinate.longitude)
                            case .userLocation:
                                if let userLocation = Self.locationManager.location {
                                    return userLocation.coordinate
                                } else {
                                    // TODO: - Show toast
                                    fallthrough
                                }
                            case nil:
                                return camera.centerCoordinate
                            }
                        }()
                        
                        LinearKeyframe(coordinate, duration: 2, timingCurve: .easeOut)
                    }
                    
                    KeyframeTrack(\MapCamera.distance) {
                        let newDistance: CLLocationDistance = {
                            switch cameraTransitionTrigger {
                            case .geometry(.annotation):
                                // Some default distance for annotations
                                return 15_000
                            case let .geometry(.polyline(coords)):
                                let mapRect = MKMapRect(coordinates: coords)
                                
                                return max(mapRect.width, mapRect.height) * 1.1
                            case .userLocation, nil:
                                return max(30_000, camera.distance)
                            }
                        }()
                        
                        LinearKeyframe(newDistance, duration: 2)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    mapButtons(proxy: proxy, frame: frame)
                }
            }
        }
        .mapScope(nspace)
        .sheet(isPresented: .constant(true)) {
            MapFeatureNavigator(selection: $presentedMapFeature, newAnnotation: newAnnotation) { newSelection in
                if let newSelection {
                    selectedMapItemTag = newSelection.tag
                    cameraTransitionTrigger = .geometry(newSelection.geometry)
                } else {
                    selectedMapItemTag = nil
                    cameraTransitionTrigger = nil
                }
                
                newAnnotation.clearProgress()
            }
            .presentationDetents(detents, selection: $selectedDetent)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled()
        }
        .onChange(of: selectedMapItemTag) {
            print(selectedMapItemTag ?? "No selection")
            
            switch selectedMapItemTag {
            case let .annotation(id):
                if let annotation = annotations.first(where: { id == $0.id }) {
                    presentedMapFeature = .annotation(annotation)
                } else {
                    // TODO: - Error handling (an annotation presentation was requested, but the annotation cannot be found)
                }
            case let .polyline(id):
                if let polyline = polylines.first(where: { id == $0.id }) {
                    presentedMapFeature = .polyline(polyline)
                } else {
                    // TODO: - Error handling (a polyline presentation was requested, but the polyline cannot be found)
                }
            case .newFeature:
                if newAnnotation.workingAnnotation != nil {
                    presentedMapFeature = .workingAnnotation
                } else {
                    // TODO: - Handle working polyline once implemented
                }
            case .none:
                cameraTransitionTrigger = nil
            }
        }
        .onChange(of: showUserLocation) {
            userLocationToggled()
        }
        .task {
            if showUserLocation && Self.locationManager.location != nil {
                if cameraTransitionTrigger != nil {
                    cameraTransitionTrigger?.toggleUserLocation()
                } else {
                    cameraTransitionTrigger = .userLocation(true)
                }
            }
        }
    }
    
    private func annotationViews(proxy: MapProxy) -> some MapContent {
        ForEach(annotations) { annotation in
            AnnotationMapOverlay(annotation: annotation, movementEnabled: true, shouldJiggle: false, foregroundColor: .orange) { newPosition in
                guard let newCoordinate = proxy.convert(
                    newPosition,
                    from: .global
                ) else {
                    // TODO: - Handle error by:
                    // - showing toast to user
                    // - sending log through analytics service with details on map proxy and provided position
                    return
                }
                
                annotation.coordinate = Coordinate(newCoordinate)
            }
        }
    }
    
    @MapContentBuilder
    private func polylineViews(proxy: MapProxy) -> some MapContent {
        ForEach(polylines) { polyline in
            PolylineMapOverlay(polyline: polyline, strokeColor: .red)
        }
    }
    
    @MapContentBuilder
    private func inProgressPin(proxy: MapProxy) -> some MapContent {
        if let newAnnotationLocation = newAnnotation.workingAnnotation?.coordinate {
            AnnotationMapOverlay(
                annotation: WorkingAnnotation(
                    coordinate: newAnnotationLocation,
                    title: newAnnotation.workingAnnotation?.title ?? ""
                ),
                shouldJiggle: newAnnotation.isShowingOptions,
                foregroundColor: .orange,
                fillColor: .blue
            ) { newPosition in
                guard let newCoordinate = proxy.convert(
                    newPosition,
                    from: .global
                ) else {
                    // TODO: - Handle error by:
                    // - showing toast to user
                    // - sending log through analytics service with details on map proxy and provided position
                    return
                }
                
                newAnnotation.apply(coordinate: Coordinate(newCoordinate))
            }
        }
    }
    
    private func mapButtons(proxy: MapProxy, frame: CGRect) -> some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                VStack(alignment: .leading, spacing: 40) {
                    MapScaleView(scope: nspace)
                    
                    MapCompass(scope: nspace)
                }
                .mapControlVisibility(.visible) // TODO: - Use a setting to determine whether controls are visible
                
                Spacer()
            }
            
            VStack(alignment: .trailing, spacing: 0) {
                let padding = buttonSize / 4
                let activeColor = Color.blue
                let inactiveColor = Color(uiColor: .darkGray)
                let cornerRadius = buttonSize / 3
                
                HStack(spacing: 0) {
                    if newAnnotation.isShowingOptions {
                        HStack {
                            Button {
                                do {
                                    let annotation = try newAnnotation.finalize()
                                    modelContext.insert(annotation)
                                    
                                    selectedMapItemTag = nil
                                    selectedDetent = .small
                                } catch {
                                    // TODO: - Handle errors by:
                                    // - Determining if error was `AnnotationFinalizationError` or some SwiftData error and handle accordingly
                                    // - Showing toast to user
                                    
                                    print(error)
                                }
                            } label: {
                                Text("Confirm")
                            }
                            
                            Divider()
                            
                            Button {
                                newAnnotation.clearProgress()
                                selectedMapItemTag = nil
                                selectedDetent = .small
                            } label: {
                                Text("Cancel")
                            }
                        }
                        .padding(.horizontal)
                        .background {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.background)
                        }
                        
                        Triangle(faceAlignment: .leading)
                            .fill(.background)
                            .frame(width: 10, height: 20)
                            .offset(x: -1)
                    }
                    
                    Button {
                        guard let coordinate = proxy.convert(
                            CGPoint(
                                x: frame.midX,
                                y: frame.midY
                            ),
                            from: .global
                        ) else {
                            print("No center, yo")
                            // TODO: - Handle Error by:
                            // - showing toast to user
                            // - sending log through analytics service with details on map proxy
                            return
                        }
                        
                        newAnnotation.apply(coordinate: coordinate)
                        selectedMapItemTag = .newFeature
                    } label: {
                        Image(systemName: "mappin")
                            .resizable()
                            .scaledToFit()
                            .padding(padding)
                            .accessibilityLabel("Create New Marker")
                    }
                    .frame(width: buttonSize)
                    .foregroundStyle(newAnnotation.isShowingOptions ? .blue : Color(uiColor: .darkGray))
                    .background {
                        UnevenRoundedRectangle(topLeadingRadius: cornerRadius, topTrailingRadius: cornerRadius)
                            .fill(.background)
                    }
                }
                .frame(height: buttonSize)
                
                Divider()
                    .frame(width: buttonSize)
            
                Button {
                    showUserLocation.toggle()
                } label: {
                    Image(systemName: showUserLocation ? "location.north.circle.fill" : "location.north.circle")
                        .resizable()
                        .scaledToFit()
                        .padding(padding)
                        .accessibilityLabel((showUserLocation ? "Hide" : "Show") + " Current Location")
                }
                .frame(width: buttonSize)
                .foregroundStyle(showUserLocation ? .blue : Color(uiColor: .darkGray))
                .background {
                    if showUserLocation {
                        Rectangle()
                            .fill(.background)
                    } else {
                        UnevenRoundedRectangle(bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius)
                            .fill(.background)
                    }
                }
                .frame(height: buttonSize)
                
                if showUserLocation {
                    Divider()
                        .frame(width: buttonSize)
                    
                    Button {
                        // TODO: - Periodically add polyline points while active (background notifications)
                        //  - Cull points that are too close or have an angle change of less than some delta
                    } label: {
                        Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath.fill")
                            .resizable()
                            .scaledToFit()
                            .padding(padding)
                            .accessibilityLabel("Track Location as a Path")
                    }
                    .frame(width: buttonSize)
                    .foregroundStyle(false ? activeColor : inactiveColor)
                    .background {
                        UnevenRoundedRectangle(bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius)
                            .fill(.background)
                    }
                    .frame(height: buttonSize)
                }
                
                Spacer()
            }
            .opacity(selectedDetent == .largeWithoutScaleEffect ? 0 : 1)
            .animation(.easeOut(duration: 0.2), value: selectedDetent)
            .animation(.easeInOut(duration: 0.2), value: showUserLocation)
        }
        .padding(.horizontal)
    }
    
    private func userLocationToggled() {
        if showUserLocation {
            Self.locationManager.requestWhenInUseAuthorization()
            
            switch Self.locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse: break
            case .restricted, .denied, .notDetermined: fallthrough
            @unknown default: showUserLocation = false
            }
            
            if Self.locationManager.location != nil {
                if cameraTransitionTrigger != nil {
                    cameraTransitionTrigger?.toggleUserLocation()
                } else {
                    cameraTransitionTrigger = .userLocation(true)
                }
            }
        }
    }
}

#Preview {
    DetailedMapView()
        .modelContainer(for: CurrentModelVersion.models, inMemory: true) { result in
            switch result {
            case let .success(container):
                let context = ModelContext(container)
                
                context.insert(AnnotationData(
                    title: WorkingAnnotation.example.title,
                    coordinate: WorkingAnnotation.example.coordinate)
                )
                context.insert(PolylineData(
                    title: WorkingPolyline.example.title,
                    coordinates: WorkingPolyline.example.coordinates)
                )
                try! context.save()
            case let .failure(error):
                print(error)
            }
        }
}
