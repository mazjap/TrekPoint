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
// - [ ] Better (or any) error handling
//    - [ ] Add red border to annotation title when user presses confirm and title is empty
//    - [ ] Add some sort of toast alert system or package
// - [ ] Add polyline support
//    - [ ] "Following user location" type polyline
//    - [ ] "Tap to draw" type polyline

enum PresentedAnnotation {
    case prototype
    case annotation(AnnotationData)
}

enum MapFeatureTag: Hashable, Identifiable {
    case annotation(UUID)
    case polyline(UUID)
    case newFeature
    
    var id: String {
        switch self {
        case let .annotation(id):
            id.uuidString
        case let .polyline(id):
            id.uuidString
        case .newFeature:
            "new_feature"
        }
    }
}

struct DetailedMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var annotations: [AnnotationData]
    @Query private var polylines: [PolylineData]
    
    @Namespace private var nspace
    
    @AppStorage("is_user_location_active") private var showUserLocation: Bool = false
    
    @State private var newAnnotation = NewAnnotationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var cameraTransitionTrigger = false
    @State private var selectedMapItemTag: MapFeatureTag?
    
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
                        LinearKeyframe(Self.locationManager.location!.coordinate, duration: 2, timingCurve: .easeOut)
                    }
                    
                    KeyframeTrack(\MapCamera.distance) {
                        LinearKeyframe(camera.distance, duration: 2)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    mapButtons(proxy: proxy, frame: frame)
                }
            }
        }
        .mapScope(nspace)
        .sheet(isPresented: .constant(true)) {
            sheetContent
                .sheet(item: $selectedMapItemTag) { tag in
                    nestedSheetContent(tag: tag)
                        .presentationDetents(detents, selection: $selectedDetent)
                        .presentationBackgroundInteraction(.enabled)
                        .interactiveDismissDisabled()
                }
                .presentationDetents(detents, selection: $selectedDetent)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
        }
        .onChange(of: selectedMapItemTag) {
            print(selectedMapItemTag ?? "No selection")
            
            guard let selectedMapItemTag else { return }
            
            if let annotation = annotations.first(where: { selectedMapItemTag == .annotation($0.id) }) {
                // TODO: - Present ModifyAnnotationView in sheet
            } else if let polyline = polylines.first(where: { selectedMapItemTag == .polyline($0.id) }) {
                // TODO: - Present ModifyPolylineView in sheet
            }
        }
        .onChange(of: showUserLocation) {
            userLocationToggled()
        }
        .task {
            if showUserLocation && Self.locationManager.location != nil {
                cameraTransitionTrigger.toggle()
            }
        }
    }
    
    private func annotationViews(proxy: MapProxy) -> some MapContent {
        ForEach(annotations) { annotation in
            Annotation(coordinate: CLLocationCoordinate2D(annotation.coordinate), anchor: .bottom) {
                DraggablePin(anchor: .bottom) { newPosition in
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
                .foregroundStyle(.red, .green)
            } label: {
                Text(annotation.title)
            }
            .tag(MapFeatureTag.annotation(annotation.id))
        }
    }
    
    @MapContentBuilder
    private func polylineViews(proxy: MapProxy) -> some MapContent {
        ForEach(polylines) { polyline in
            MapPolyline(coordinates: polyline.clCoordinates)
                .stroke(.red, lineWidth: 5)
                .tag(MapFeatureTag.polyline(polyline.id))
        }
    }
    
    @MapContentBuilder
    private func inProgressPin(proxy: MapProxy) -> some MapContent {
        if let newAnnotationLocation = newAnnotation.workingAnnotation?.coordinate {
            let clCoordinate = CLLocationCoordinate2D(newAnnotationLocation)
            
            Annotation(coordinate: clCoordinate, anchor: .bottom) {
                DraggablePin(shouldJiggle: !newAnnotation.isShowingOptions, anchor: .bottom) { newPosition in
                    guard let newCoordinate = proxy.convert(
                        newPosition,
                        from: .global
                    ) else {
                        // TODO: - Handle error by:
                        // - showing toast to user
                        // - sending log through analytics service with details on map proxy and provided position
                        return
                    }
                    
                    self.newAnnotation.apply(coordinate: newCoordinate)
                }
                .foregroundStyle(.blue)
            } label: {
                
            }
            .tag(newAnnotation.tag)
        }
    }
    
    private func mapButtons(proxy: MapProxy, frame: CGRect) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 40) {
                MapScaleView(scope: nspace)
                
                MapCompass(scope: nspace)
            }
            
            VStack(spacing: 0) {
                let padding = buttonSize / 4
                let activeColor = Color.blue
                let inactiveColor = Color(uiColor: .darkGray)
                let cornerRadius = buttonSize / 3
                
                HStack(spacing: 0) {
                    Spacer()
                    
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
                    .foregroundStyle(newAnnotation.workingAnnotation?.coordinate == nil ? Color(uiColor: .darkGray) : .blue)
                    .background {
                        UnevenRoundedRectangle(topLeadingRadius: cornerRadius, topTrailingRadius: cornerRadius)
                            .fill(.background)
                    }
                }
                .frame(height: buttonSize)
                
                Divider()
                
                HStack {
                    Spacer()
                    
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
                }
                .frame(height: buttonSize)
                
                if showUserLocation {
                    Divider()
                    
                    HStack {
                        Spacer()
                        
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
    
    private var sheetContent: some View {
        NavigationStack {
            List {
                if annotations.isEmpty && polylines.isEmpty {
                    Text("No content")
                }
                
                if !annotations.isEmpty {
                    Section("Annotations") {
                        ForEach(annotations) { item in
                            NavigationLink {
                                ModifyAnnotationView(annotation: item)
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundStyle(.red, .green)
                                    
                                    Text(item.title)
                                }
                            }
                        }
                        .onDelete(perform: deleteAnnotations)
                    }
                }
                
                if !polylines.isEmpty {
                    Section("Paths") {
                        ForEach(polylines) { item in
                            NavigationLink {
                                // TODO: - Add ModifyPolylineView here
                            } label: {
                                HStack {
                                    Image(systemName: "point.topleft.down.to.point.bottomright.curvepath.fill")
                                    
                                    Text(item.title)
                                }
                            }
                        }
                        .onDelete(perform: deletePolylines)
                    }
                }
            }
            .padding(.top, -20)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .navigationTitle("My Items")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func nestedSheetContent(tag: MapFeatureTag) -> some View {
        switch tag {
        case .newFeature:
            let protoAnnotationBinding = $newAnnotation.workingAnnotation.safelyUnwrapped(.init(coordinate: .random))
            
            AnnotationDetailView(coordinate: protoAnnotationBinding.coordinate, title: protoAnnotationBinding.title)
        case let .annotation(id):
            let annotation = annotations.first(where: { $0.id == id })!
            let annotationBinding = Bindable(annotation)
            
            AnnotationDetailView(coordinate: annotationBinding.coordinate, title: annotationBinding.title)
        case let .polyline(id):
            let polyline = polylines.first(where: { $0.id == id })!
            let polylineBinding = Bindable(polyline)
            
            PolylineDetailView(coordinates: polylineBinding.coordinates, title: polylineBinding.title)
        }
    }
    
    private func deleteAnnotations(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(annotations[index])
            }
        }
    }
    
    private func deletePolylines(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(polylines[index])
            }
        }
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
                cameraTransitionTrigger.toggle()
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
                context.insert(AnnotationData(title: "Random Location", coordinate: .random))
                context.insert(PolylineData.example)
            case let .failure(error):
                print(error)
            }
        }
}
