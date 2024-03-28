import SwiftUI
import SwiftData
import MapKit

// Tasks:
// - [x] Get user's location working
// - [x] Get DraggablePin to relocate correctly on drag gesture
//    - [x] (it's getting set to slightly above the drop location)
// - [ ] Confirm newly created annotation
//    - [ ] Add tap gesture to confirm location
//    - [ ] Create AnnotationData for given coordinate and clear newAnnotationLocation
// - [ ] Add path support

struct DetailedMapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var annotations: [AnnotationData]
    
    @Namespace private var nspace
    
    @AppStorage("is_user_location_active") private var showUserLocation: Bool = false
    
    @State private var selectedMapItemTag: String?
    @State private var newAnnotationLocation: Coordinate?
    
    @State private var selectedDetent = PresentationDetent.small
    
    @ScaledMetric(relativeTo: .title) private var buttonSize = 52
    
    static private let location = CLLocationManager()
    private let detents: Set<PresentationDetent> = .defaultMapSheetDetents
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            
            MapReader { proxy in
                Map(selection: $selectedMapItemTag, scope: nspace) {
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
                    
                    if let newAnnotationLocation {
                        let clCoordinate = CLLocationCoordinate2D(newAnnotationLocation)
                        
                        Annotation(coordinate: clCoordinate, anchor: .bottom) {
                            DraggablePin(shouldJiggle: true, anchor: .bottom) { newPosition in
                                guard let newCoordinate = proxy.convert(
                                    newPosition,
                                    from: .global
                                ) else {
                                    // TODO: - Handle error by:
                                    // - showing toast to user
                                    // - sending log through analytics service with details on map proxy and provided position
                                    return
                                }
                                
                                self.newAnnotationLocation = Coordinate(newCoordinate)
                            }
                            .foregroundStyle(.red, .green)
                        } label: {
                            
                        }
                        .tag("annotation in the making")
                    }
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .mapControlVisibility(.hidden)
                .overlay(alignment: .topTrailing) {
                    mapButtons(proxy: proxy, frame: frame)
                }
            }
        }
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
            }
            .presentationDetents(detents, selection: $selectedDetent)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()
        }
        .onChange(of: selectedMapItemTag) {
            print(selectedMapItemTag ?? "No selection")
        }
        .onChange(of: showUserLocation) {
            if showUserLocation {
                Self.location.requestWhenInUseAuthorization()
                
                switch Self.location.authorizationStatus {
                case .authorizedAlways, .authorizedWhenInUse: break
                case .restricted, .denied, .notDetermined: fallthrough
                @unknown default: showUserLocation = false
                }
            }
        }
        .mapScope(nspace)
    }
    
    private func mapButtons(proxy: MapProxy, frame: CGRect) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 40) {
                MapScaleView(scope: nspace)
                
                MapCompass(scope: nspace)
                
                Spacer()
            }
            
            Spacer()
            
            VStack {
                VStack(spacing: 0) {
                    let padding = buttonSize / 4
                    
                    if showUserLocation {
                        Button {
                            // TODO: - Periodically add path points while active (background notifications)
                        } label: {
                            Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath.fill")
                                .resizable()
                                .scaledToFit()
                                .accessibilityLabel("Track Location as a Path")
                        }
                        .padding(padding)
                        .frame(height: buttonSize)
                        
                        Divider()
                    }
                    
                    Button {
                        newAnnotationLocation = proxy.convert(CGPoint(x: frame.midX, y: frame.midY), from: .global).map { Coordinate($0) }
                        
                        if newAnnotationLocation == nil {
                            print("No center, yo")
                            // TODO: - Handle Error by:
                            // - showing toast to user
                            // - sending log through analytics service with details on map proxy
                        }
                    } label: {
                        Image(systemName: "mappin")
                            .resizable()
                            .scaledToFit()
                            .accessibilityLabel("Create New Marker")
                            .padding(padding)
                    }
                    .frame(height: buttonSize)
                    
                    Divider()
                    
                    Button {
                        showUserLocation.toggle()
                    } label: {
                        Image(systemName: showUserLocation ? "location.fill" : "location")
                            .resizable()
                            .scaledToFit()
                            .accessibilityLabel((showUserLocation ? "Hide" : "Show") + " Current Location")
                            .padding(padding)
                    }
                    .frame(height: buttonSize)
                }
                .foregroundStyle(.black)
                .background {
                    RoundedRectangle(cornerRadius: buttonSize / 3)
                        .fill(Color.white.gradient)
                }
                .frame(width: buttonSize)
                .opacity(selectedDetent == .largeWithoutScaleEffect ? 0 : 1)
                .animation(.easeOut.speed(2), value: selectedDetent)
                
                Spacer()
            }
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
}
