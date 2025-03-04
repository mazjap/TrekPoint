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
// - [x] Add polyline support
//    - [x] "Following user location" type polyline
//      - [x] While using the app
//      - [x] While app is in background
//    - [x] "Tap to draw" type polyline
// - [ ] Better (or any) error handling
//    - [ ] Add red border to annotation title when user presses confirm and title is empty
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
//   - [ ] Elevation data display
//   - [ ] Weather integration
//   - [ ] Public land boundaries overlay

struct DetailedMapView: View {
    @Environment(LocationTrackingManager.self) private var locationManager
    @Environment(NewPolylineManager.self) private var newPolyline
    @Environment(NewAnnotationManager.self) private var newAnnotation
    @Environment(\.modelContext) private var modelContext
    @Query private var annotations: [AnnotationData]
    @Query private var polylines: [PolylineData]
    
    @Namespace private var nspace
    @ScaledMetric(relativeTo: .title) private var buttonSize = 52
    
    @State private var editingMode: MapEditingMode = .view
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedMapItemTag: MapFeatureTag?
    @State private var presentedMapFeature: MapFeatureToPresent?
    @State private var selectedDetent = PresentationDetent.small
    @Binding private var toastReasons: [ToastReason]
    
    private let detents: Set<PresentationDetent> = .defaultMapSheetDetents
    
    init(toastReasons: Binding<[ToastReason]>) {
        self._toastReasons = toastReasons
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            MapReader { proxy in
                Map(position: $cameraPosition, selection: $selectedMapItemTag, scope: nspace) {
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
                    if editingMode == .drawPolyline {
                        guard let coordinate = proxy.convert(
                            location,
                            from: .local
                        ) else {
                            return
                        }
                        
                        newPolyline.append(coordinate)
                        // If this is the first point, show the options UI
                        if newPolyline.workingPolyline?.coordinates.count == 1 {
                            selectedMapItemTag = .newFeature
                        }
                    }
                }
                .overlay(alignment: .topTrailing) {
                    mapButtons(proxy: proxy, frame: frame)
                }
            }
        }
        .mapScope(nspace)
        .sheet(isPresented: .constant(true)) {
            MapFeatureNavigator(
                selection: $presentedMapFeature,
                isInEditingMode: Binding { editingMode != .view } set: { _ in editingMode = .view },
                toastReasons: $toastReasons,
                newAnnotation: newAnnotation,
                newPolyline: newPolyline
            ) { newSelection in
                newAnnotation.clearProgress()
                
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
            } onTrackingPolylineCreated: {
                locationManager.stopTracking()
                editingMode = .view
            }
            .modelContext(modelContext)
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
                    // TODO: - Send to some analytics service
                    toastReasons.append(.somethingWentWrong(.message("Presentation of annotation with id: \(id) was requested, but no such map feature exists")))
                }
            case let .polyline(id):
                if let polyline = polylines.first(where: { id == $0.id }) {
                    presentedMapFeature = .polyline(polyline)
                } else {
                    // TODO: - Send to some analytics service
                    toastReasons.append(.somethingWentWrong(.message("Presentation of polyline with id: \(id) was requested, but no such map feature exists")))
                }
            case .newFeature:
                if newAnnotation.workingAnnotation != nil {
                    presentedMapFeature = .workingAnnotation
                } else if newPolyline.workingPolyline != nil {
                    presentedMapFeature = .workingPolyline
                } else {
                    // TODO: - Send to some analytics service
                    toastReasons.append(.somethingWentWrong(.message("Presentation of the currently working feature (either annotation or polyline) was requested, but none exist")))
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
            guard newPolyline.isTrackingPolyline,
                  let lastLocation = locationManager.lastLocation
            else { return }
            
            newPolyline.appendCurrentLocation(lastLocation.coordinate)
        }
        .task {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("RestoreTrackingSession"),
                object: nil,
                queue: .main
            ) { notification in
                if let trackingID = notification.userInfo?["trackingID"] as? UUID {
                    // Restore the tracking session
                    self.restoreTrackingSession(trackingID: trackingID)
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
                    toastReasons.append(.somethingWentWrong(.message("Annotation movement was not possible. (\(newPosition) could not be converted to a map coordinate")))
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
                    // TODO: - Send to some analytics service
                    toastReasons.append(.somethingWentWrong(.message("Working annotation movement was not possible. (\(newPosition) could not be converted to a map coordinate")))
                    return
                }
                
                newAnnotation.apply(coordinate: Coordinate(newCoordinate))
            }
        }
    }
    
    @MapContentBuilder
    private func inProgressPolyline(proxy: MapProxy) -> some MapContent {
        if let workingPolyline = newPolyline.workingPolyline, !workingPolyline.coordinates.isEmpty {
            PolylineMapOverlay(
                polyline: workingPolyline,
                strokeColor: newPolyline.isTrackingPolyline ? .purple : .blue
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
                        fillColor: newPolyline.isTrackingPolyline ? .purple : .blue
                    ) { newPosition in
                        guard let newCoordinate = proxy.convert(
                            newPosition,
                            from: .global
                        ) else {
                            // TODO: - Send to some analytics service
                            toastReasons.append(.somethingWentWrong(.message("Working polyline point movement was not possible. (\(newPosition) could not be converted to a map coordinate")))
                            return
                        }
                        
                        newPolyline.move(index: index, to: newCoordinate)
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
                    if newAnnotation.isShowingOptions {
                        HStack {
                            Button {
                                do {
                                    let annotation = try newAnnotation.finalize()
                                    modelContext.insert(annotation)
                                    
                                    selectedMapItemTag = nil
                                    selectedDetent = .small
                                } catch let annotationError as AnnotationFinalizationError {
                                    toastReasons.append(.annotationCreationError(annotationError))
                                } catch {
                                    // TODO: - Send to some analytics service
                                    toastReasons.append(.somethingWentWrong(.error(error)))
                                }
                            } label: {
                                Text("Confirm")
                            }
                            
                            Divider()
                            
                            Button {
                                newAnnotation.undo()
                            } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward.circle")
                            }
                            .disabled(!newAnnotation.canUndo)
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
                        if newAnnotation.workingAnnotation == nil {
                            let midPoint = CGPoint(x: frame.midX, y: frame.midY)
                            
                            guard let coordinate = proxy.convert(
                                midPoint,
                                from: .global
                            ) else {
                                // TODO: - Send to some analytics service
                                toastReasons.append(.somethingWentWrong(.message("Annotation creation was not possible. (\(midPoint) could not be converted to a map coordinate")))
                                
                                return
                            }
                            
                            newAnnotation.apply(coordinate: coordinate)
                            selectedMapItemTag = .newFeature
                        } else {
                            newAnnotation.clearProgress()
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
                    .foregroundStyle(newAnnotation.isShowingOptions ? activeColor : inactiveColor)
                    .background {
                        UnevenRoundedRectangle(topLeadingRadius: cornerRadius, topTrailingRadius: cornerRadius)
                            .fill(.background)
                    }
                }
                .frame(height: buttonSize)
                
                Divider()
                    .frame(width: buttonSize)
                
                HStack(spacing: 0) {
                    if newPolyline.isShowingOptions && newPolyline.isDrawingPolyline {
                        HStack {
                            Button {
                                do {
                                    let polyline = try newPolyline.finalize()
                                    modelContext.insert(polyline)
                                    
                                    selectedMapItemTag = nil
                                    selectedDetent = .small
                                } catch let polylineError as PolylineFinalizationError {
                                    toastReasons.append(.polylineCreationError(polylineError))
                                } catch {
                                    // TODO: - Send to some analytics service
                                    toastReasons.append(.somethingWentWrong(.error(error)))
                                }
                            } label: {
                                Text("Confirm")
                            }
                            
                            Divider()
                            
                            Button {
                                newPolyline.undo()
                            } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward.circle")
                            }
                            .disabled(!newPolyline.canUndo)
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
                        if editingMode == .drawPolyline {
                            editingMode = .view
                            newPolyline.clearProgress()
                            selectedMapItemTag = nil
                            selectedDetent = .small
                        } else {
                            editingMode = .drawPolyline
                            
                            // Clear any in-progress polyline
                            newPolyline.clearProgress()
                            newPolyline.append([Coordinate]())
                            selectedMapItemTag = .newFeature
                        }
                    } label: {
                        Image(systemName: newPolyline.isDrawingPolyline ? "hand.draw.fill" : "hand.draw")
                            .resizable()
                            .scaledToFit()
                            .padding(padding)
                            .accessibilityLabel(newPolyline.isDrawingPolyline ? "Stop Drawing Path" : "Draw Path")
                    }
                    .frame(width: buttonSize, height: buttonSize)
                    .foregroundStyle(newPolyline.isDrawingPolyline ? activeColor : inactiveColor)
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
                        if newPolyline.isTrackingPolyline {
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
                                            let polyline = try newPolyline.finalize()
                                            modelContext.insert(polyline)
                                            
                                            editingMode = .view
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
                            if editingMode == .locationTrackedPolyline {
                                editingMode = .view
                                newPolyline.clearProgress()
                                selectedMapItemTag = nil
                                selectedDetent = .small
                                locationManager.stopTracking()
                            } else {
                                editingMode = .locationTrackedPolyline
                                newPolyline.clearProgress()
                                newPolyline.startLocationTracking(currentLocation: locationManager.startTracking())
                                selectedMapItemTag = .newFeature
                            }
                        } label: {
                            Image(systemName: newPolyline.isTrackingPolyline ? "location.north.line.fill" : "location.north.line")
                                .resizable()
                                .scaledToFit()
                                .padding(padding)
                                .accessibilityLabel(newPolyline.isTrackingPolyline ? "Stop Tracking" : "Track My Path")
                        }
                        .frame(width: buttonSize)
                        .foregroundStyle(newPolyline.isTrackingPolyline ? activeColor : inactiveColor)
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
    
    private func restoreTrackingSession(trackingID: UUID) {
        // Get all pending locations
        let pendingLocations = PersistenceController.shared.getPendingLocations(for: trackingID)
        
        // Create a new polyline with these locations
        if !pendingLocations.isEmpty {
            // Start a new tracked polyline
            editingMode = .locationTrackedPolyline
            newPolyline.clearProgress()
            newPolyline.startLocationTracking(currentLocation: pendingLocations.first)
            
            // Add all the pending locations
            for location in pendingLocations {
                newPolyline.appendCurrentLocation(location)
            }
            
            // Clear the pending locations now that we've restored them
            PersistenceController.shared.clearPendingLocations(for: trackingID)
            
            // Continue tracking
            let _ = locationManager.startTracking()
            selectedMapItemTag = .newFeature
        }
    }
}

#Preview {
    DetailedMapView(toastReasons: .constant([]))
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
                    coordinates: WorkingPolyline.example.coordinates,
                    isLocationTracked: false
                ))
                try! context.save()
            case let .failure(error):
                print(error)
            }
        }
}
