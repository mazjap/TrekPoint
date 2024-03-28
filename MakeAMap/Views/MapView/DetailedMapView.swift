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
// - [ ] Add path support
//    - [ ] "Following user location" type path
//    - [ ] "Tap to draw" type path

enum PresentedAnnotation {
    case prototype
    case annotation(AnnotationData)
}

struct DetailedMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var annotations: [AnnotationData]
    
    @Namespace private var nspace
    
    @AppStorage("is_user_location_active") private var showUserLocation: Bool = false
    
    @State private var newAnnotation = NewAnnotationManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var cameraTransitionTrigger = false
    @State private var selectedMapItemTag: String?
    
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
                        .tag(annotation.id.uuidString)
                    }
                    
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
            VStack {
                NavigationStack {
                    List {
                        if annotations.isEmpty {
                            Text("No content")
                        } else {
                            ForEach(annotations) { item in
                                NavigationLink {
                                    ModifyAnnotationView(annotation: item)
                                } label: {
                                    Text(item.title)
                                }
                            }
                            .onDelete(perform: deleteItems)
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
                .sheet(item: $selectedMapItemTag) { tag in
                    let (coordinate, title): (Binding<Coordinate>, Binding<String>) = {
                        switch tag {
                        case newAnnotation.tag:
                            let protoAnnotationBinding = $newAnnotation.workingAnnotation.safelyUnwrapped(.init(coordinate: .random))
                            
                            return (protoAnnotationBinding.coordinate, protoAnnotationBinding.title)
                        default:
                            let annotation = annotations.first(where: { $0.id.uuidString == tag })!
                            let annotationBinding = Bindable(annotation)
                            
                            return (annotationBinding.coordinate, annotationBinding.title)
                        }
                    }()
                    
                    AnnotationDetailView(coordinate: coordinate, title: title)
                        .presentationDetents(detents, selection: $selectedDetent)
                        .presentationBackgroundInteraction(.enabled)
                        .interactiveDismissDisabled()
                }
            }
            .presentationDetents(detents, selection: $selectedDetent)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()
        }
        .onChange(of: selectedMapItemTag) {
            print(selectedMapItemTag ?? "No selection")
            
            if let selectedMapItemTag,
               let annotation = annotations.first(where: { $0.id.uuidString == selectedMapItemTag }) {
                // TODO: - Present ModifyAnnotationView in sheet
            }
        }
        .onChange(of: showUserLocation) {
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
        .task {
            if showUserLocation && Self.locationManager.location != nil {
                cameraTransitionTrigger.toggle()
            }
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
                        selectedMapItemTag = newAnnotation.tag
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
                            // TODO: - Periodically add path points while active (background notifications)
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
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(annotations[index])
            }
        }
    }
}

#Preview {
    DetailedMapView()
        .modelContainer(for: ModelVersion.models, inMemory: true) { result in
            switch result {
            case let .success(container):
                let context = ModelContext(container)
                context.insert(AnnotationData(title: "Random Location", coordinate: .random))
            case let .failure(error):
                print(error)
            }
        }
}

extension String: Identifiable {
    public var id: String { self }
}
