import SwiftUI

struct PolylineDetailView: View {
    private enum Storage {
        case polylineData(PolylineData)
        case workingPolyline(Binding<WorkingPolyline>)
    }
    
    private let storage: Storage
    
    init(polyline: PolylineData) {
        self.storage = .polylineData(polyline)
    }
    
    init(polyline: Binding<WorkingPolyline>) {
        self.storage = .workingPolyline(polyline)
    }
    
    var body: some View {
        switch storage {
        case let .polylineData(polyline):
            let bindable = Bindable(polyline)
            PolylineDetailViewImplementation(polyline: polyline, coordinates: bindable.coordinates, title: bindable.title)
        case let .workingPolyline(polyline):
            PolylineDetailViewImplementation(polyline: polyline.wrappedValue, coordinates: polyline.coordinates, title: polyline.title)
        }
    }
}

fileprivate struct PolylineDetailViewImplementation: View {
    private let feature: MapFeature
    @State private var previewId = UUID()
    @Binding private var coordinates: [Coordinate]
    @Binding private var title: String
    
    init(polyline: any PolylineProvider, coordinates: Binding<[Coordinate]>, title: Binding<String>) {
        self.feature = .polyline(polyline)
        self._coordinates = coordinates
        self._title = title
    }
    
    var body: some View {
        VStack(spacing: 0) {
            MapPreview(feature: feature)
                .id(previewId)
                .frame(height: 240)
                .onChange(of: coordinates) {
                    previewId = UUID()
                }
            
            Form {
                TextField("Name this path", text: $title)
                    .font(.title2.bold())
                    .overlay {
                        if title.isEmpty {
                            Color.red.opacity(0.2)
                                .allowsHitTesting(false)
                            // TODO: - Don't use magic number
                                .padding(.horizontal, -20)
                                .padding(.vertical, -10)
                        }
                    }
                
                DisclosureGroup("Coordinates") {
                    Grid(alignment: .leading) {
                        GridRow {
                            Text("#")
                            
                            Text("Latitude:")
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity)
                            
                            Text("Longitude:")
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity)
                        }
                        
                        if !coordinates.isEmpty {
                            Divider()
                        }
                        
                        ForEach(Array(coordinates.enumerated()), id: \.1.id) { (index, coordinate) in
                            Spacer()
                                .frame(height: 10)
                            
                            GridRow {
                                Text("\(index + 1)")
                                
                                let latBinding = Binding {
                                    coordinate.latitude
                                } set: {
                                    coordinates[index].latitude = $0
                                }
                                
                                let lngBinding = Binding {
                                    coordinate.longitude
                                } set: {
                                    coordinates[index].longitude = $0
                                }
                                
                                TextField("", value: latBinding, format: .number)
                                
                                TextField("", value: lngBinding, format: .number)
                            }
                            .textFieldStyle(.roundedBorder)
                            
                            if index != coordinates.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .overlay {
                    if coordinates.isEmpty {
                        Color.red.opacity(0.2)
                            .padding(-40)
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var polyline = WorkingPolyline.example
    
    PolylineDetailView(polyline: $polyline)
}
