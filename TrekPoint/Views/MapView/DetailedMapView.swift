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

struct DetailedMapView: View {
    @Dependency(\.locationTrackingManager) private var locationManager
    @Dependency(\.annotationPersistenceManager) private var annotationManager
    @Dependency(\.polylinePersistenceManager) private var polylineManager
    @Dependency(\.toastManager) private var toastManager: ToastManager
    
    @Query private var annotations: [AnnotationData]
    @Query private var polylines: [PolylineData]
    
    @Namespace private var nspace
    @ScaledMetric(relativeTo: .title) private var buttonSize = 52
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedMapItemTag: MapFeatureTag?
    @State private var presentedMapFeature: MapFeatureToPresent?
    @State private var selectedDetent = PresentationDetent.small
    
    @Binding private var showSheet: Bool
    
    private let detents: Set<PresentationDetent> = .defaultMapSheetDetents
    
    init(showSheet: Binding<Bool>) {
        self._showSheet = showSheet
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            MapReader { proxy in
                Map(position: $cameraPosition, bounds: MapCameraBounds(minimumDistance: 0, maximumDistance: .infinity), selection: $selectedMapItemTag, scope: nspace) {
                    if locationManager.isUserLocationActive {
                        UserAnnotation()
                    }
                    
                    annotationViews(proxy: proxy)
                    
                    polylineViews(proxy: proxy)
                    
                    inProgressPolyline(proxy: proxy)
                    
                    inProgressPin(proxy: proxy)
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .mapControlVisibility(.hidden)
                .onTapGesture { location in
                    guard polylineManager.isDrawingPolyline else { return }
                    guard let coordinate = proxy.convert(
                        location,
                        from: .local
                    ) else {
                        return
                    }
                    
                    polylineManager.appendWorkingPolylineCoordinate(Coordinate(coordinate))
                    
                    // If this is the first point, show the options UI
                    if polylineManager.workingPolyline?.coordinates.count == 1 {
                        selectedMapItemTag = .newFeature
                    }
                }
                .overlay(alignment: .topTrailing) {
                    mapButtons(proxy: proxy, frame: frame)
                }
            }
        }
        .mapScope(nspace)
        .sheet(isPresented: $showSheet) {
            MapFeatureNavigator(
                selection: $presentedMapFeature,
                annotations: annotations,
                polylines: polylines
            ) { newSelection in
                annotationManager.clearWorkingAnnotationProgress()

                if let newSelection {
                    selectedMapItemTag = newSelection.tag
                    
                    withAnimation(.easeOut) {
                        switch newSelection {
                        case let .annotation(annotation):
                            cameraPosition = .region(MKCoordinateRegion(center: annotation.clCoordinate, latitudinalMeters: 15_000, longitudinalMeters: 15_000))
                        case let .polyline(polyline):
                            cameraPosition = .rect(MKMapRect(coordinates: polyline.clCoordinates))
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
        ) { item in
            HStack {
                Image(systemName: "exclamationmark.circle")
                
                switch item {
                case .annotationCreationError(.emptyTitle), .polylineCreationError(.emptyTitle):
                    Text("Missing a title")
                case .annotationCreationError(.noCoordinate):
                    VStack(alignment: .leading) {
                        Text("Missing a coordinate")
                        
                        Text("Try dragging the pin to place it on the map.")
                            .font(.body)
                    }
                case .annotationCreationError(.noAnnotation):
                    Text("Something went wrong")
                case .polylineCreationError(.tooFewCoordinates(let required, let have)):
                    VStack(alignment: .leading) {
                        Text("Paths need at least \(required) coordinates")
                        
                        Text("This path currently has \(have) coordinates. Try adding more points to complete the path.")
                            .font(.body)
                    }
                case .somethingWentWrong:
                    Text("Something went wrong")
                }
            }
            .font(.title3.bold())
            .foregroundStyle(.red)
            .padding()
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
                withAnimation(.easeOut) {
                    cameraPosition = .userLocation(fallback: .automatic)
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
                withAnimation {
                    cameraPosition = .userLocation(fallback: .automatic)
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
        ForEach(polylines) { polyline in
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
                guard let newCoordinate = proxy.convert(
                    newPosition,
                    from: .global
                ) else {
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
            ForEach(Array(workingPolyline.coordinates.enumerated()), id: \.1.id) { index, coordinate in
                Annotation(
                    "Point \(index + 1)",
                    coordinate: CLLocationCoordinate2D(coordinate),
                    anchor: .center
                ) {
                    DraggablePolylinePoint(
                        movementEnabled: !workingPolyline.isLocationTracked,
                        fillColor: polylineManager.isTrackingPolyline ? .purple : .blue
                    ) { newPosition in
                        guard let newCoordinate = proxy.convert(
                            newPosition,
                            from: .global
                        ) else {
                            // TODO: - Send to some analytics service
                            toastManager.addBreadForToasting(.somethingWentWrong(.message("Working polyline point movement was not possible. (\(newPosition) could not be converted to a map coordinate")))
                            return
                        }
                        
                        polylineManager.moveWorkingPolylineCoordinate(at: index, to: newCoordinate)
                    }
                }
                .tag(MapFeatureTag.newFeature)
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
                    if annotationManager.isShowingOptions {
                        HStack {
                            Button {
                                do {
                                    try polylineManager.finalizeWorkingPolyline()
                                    
                                    selectedMapItemTag = nil
                                    selectedDetent = .small
                                } catch {
                                    // TODO: - Send to some analytics service
                                    toastManager.commitFeatureCreationError(error)
                                }
                            } label: {
                                Text("Confirm")
                            }
                            
                            Divider()
                            
                            Button {
                                annotationManager.undo()
                            } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward.circle")
                            }
                            .disabled(!annotationManager.canUndo)
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
                        if annotationManager.workingAnnotation == nil {
                            let midPoint = CGPoint(x: frame.midX, y: frame.midY)
                            
                            guard let coordinate = proxy.convert(
                                midPoint,
                                from: .global
                            ) else {
                                // TODO: - Send to some analytics service
                                toastManager.addBreadForToasting(.somethingWentWrong(.message("Annotation creation was not possible. (\(midPoint) could not be converted to a map coordinate")))
                                
                                return
                            }
                            
                            annotationManager.changeWorkingAnnotationsCoordinate(to: Coordinate(coordinate))
                            selectedMapItemTag = .newFeature
                        } else {
                            annotationManager.clearWorkingAnnotationProgress()
                            selectedMapItemTag = nil
                            selectedDetent = .small
                        }
                    } label: {
                        Image(systemName: "mappin")
                            .resizable()
                            .scaledToFit()
                            .padding(padding)
                            .accessibilityLabel("Create New Marker")
                    }
                    .frame(width: buttonSize)
                    .foregroundStyle(annotationManager.isShowingOptions ? activeColor : inactiveColor)
                    .background {
                        UnevenRoundedRectangle(topLeadingRadius: cornerRadius, topTrailingRadius: cornerRadius)
                            .fill(.background)
                    }
                }
                .frame(height: buttonSize)
                
                Divider()
                    .frame(width: buttonSize)
                
                HStack(spacing: 0) {
                    if polylineManager.isShowingOptions && polylineManager.isDrawingPolyline {
                        HStack {
                            Button {
                                do {
                                    _ = try polylineManager.finalizeWorkingPolyline()
                                    
                                    selectedMapItemTag = nil
                                    selectedDetent = .small
                                } catch {
                                    // TODO: - Send to some analytics service
                                    toastManager.commitFeatureCreationError(error)
                                }
                            } label: {
                                Text("Confirm")
                            }
                            
                            Divider()
                            
                            Button {
                                polylineManager.undo()
                            } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward.circle")
                            }
                            .disabled(!polylineManager.canUndo)
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
                        if polylineManager.workingPolyline != nil {
                            polylineManager.clearWorkingPolylineProgress()
                            selectedMapItemTag = nil
                            selectedDetent = .small
                        } else {
                            polylineManager.startNewWorkingPolyline()
                            selectedMapItemTag = .newFeature
                        }
                    } label: {
                        Image(systemName: polylineManager.isDrawingPolyline ? "hand.draw.fill" : "hand.draw")
                            .resizable()
                            .scaledToFit()
                            .padding(padding)
                            .accessibilityLabel(polylineManager.isDrawingPolyline ? "Stop Drawing Path" : "Draw Path")
                    }
                    .frame(width: buttonSize, height: buttonSize)
                    .foregroundStyle(polylineManager.isDrawingPolyline ? activeColor : inactiveColor)
                    .background {
                        Rectangle()
                            .fill(.background)
                    }
                }
                .frame(height: buttonSize)
                
                Divider()
                    .frame(width: buttonSize)
            
                Button {
                    if locationManager.isUserLocationActive {
                        locationManager.hideUserLocation()
                    } else {
                        locationManager.showUserLocation()
                    }
                } label: {
                    Image(systemName: locationManager.isUserLocationActive ? "location.north.circle.fill" : "location.north.circle")
                        .resizable()
                        .scaledToFit()
                        .padding(padding)
                        .accessibilityLabel((locationManager.isUserLocationActive ? "Hide" : "Show") + " Current Location")
                }
                .frame(width: buttonSize)
                .foregroundStyle(locationManager.isUserLocationActive ? activeColor : inactiveColor)
                .background {
                    if locationManager.isUserLocationActive {
                        Rectangle()
                            .fill(.background)
                    } else {
                        UnevenRoundedRectangle(bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius)
                            .fill(.background)
                    }
                }
                .frame(height: buttonSize)
                
                if locationManager.isUserLocationActive {
                    Divider()
                        .frame(width: buttonSize)
                    
                    HStack(spacing: 0) {
                        if polylineManager.isTrackingPolyline {
                            HStack {
                                Text("R")
                                    .font(.title)
                                    .minimumScaleFactor(0.1)
                                    .frame(width: buttonSize / 2, height: buttonSize / 2)
                                    .padding(.vertical, 6)
                                    .background {
                                        Circle()
                                            .fill(.red)
                                    }
                                
                                HStack(spacing: 0) {
                                    Button {
                                        do {
                                            _ = try polylineManager.finalizeWorkingPolyline()
                                            
                                            locationManager.stopTracking()
                                        } catch {
                                            print(error)
                                            // Show error toast
                                        }
                                    } label: {
                                        Text("Confirm")
                                    }
                                    .frame(height: buttonSize)
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
                            }
                        }
                        
                        Button {
                            if polylineManager.workingPolyline != nil {
                                polylineManager.clearWorkingPolylineProgress()
                                selectedMapItemTag = nil
                                selectedDetent = .small
                                locationManager.stopTracking()
                            } else {
                                polylineManager.startNewLocationTrackedPolyline(withUserCoordinate: locationManager.startTracking())
                                selectedMapItemTag = .newFeature
                            }
                        } label: {
                            Image(systemName: polylineManager.isTrackingPolyline ? "location.north.line.fill" : "location.north.line")
                                .resizable()
                                .scaledToFit()
                                .padding(padding)
                                .accessibilityLabel(polylineManager.isTrackingPolyline ? "Stop Tracking" : "Track My Path")
                        }
                        .frame(width: buttonSize)
                        .foregroundStyle(polylineManager.isTrackingPolyline ? activeColor : inactiveColor)
                        .background {
                            UnevenRoundedRectangle(bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius)
                                .fill(.background)
                        }
                    }
                    .frame(height: buttonSize)
                }
                
                Spacer()
            }
            .opacity(selectedDetent == .largeWithoutScaleEffect ? 0 : 1)
            .animation(.easeOut(duration: 0.2), value: selectedDetent)
            .animation(.easeInOut(duration: 0.2), value: locationManager.isUserLocationActive)
        }
        .padding(.horizontal)
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
