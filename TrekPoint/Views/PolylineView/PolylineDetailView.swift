import SwiftUI

struct PolylineDetailView: View {
    private enum Storage {
        case polylineData(Bindable<PolylineData>)
        case workingPolyline(Binding<WorkingPolyline>)
        
        var wrappedValue: any PolylineProvider {
            switch self {
            case let .polylineData(polyline): polyline.wrappedValue
            case let .workingPolyline(polyline): polyline.wrappedValue
            }
        }
        
        var coordinates: Binding<[Coordinate]> {
            switch self {
            case let .polylineData(polyline): polyline.coordinates
            case let .workingPolyline(polyline): polyline.coordinates
            }
        }
        
        var title: Binding<String> {
            switch self {
            case let .polylineData(polyline): polyline.title
            case let .workingPolyline(polyline): polyline.title
            }
        }
        
        var userDescription: Binding<String> {
            switch self {
            case let .polylineData(polyline): polyline.userDescription
            case let .workingPolyline(polyline): polyline.userDescription
            }
        }
    }
    
    @State private var previewId = UUID()
    private let storage: Storage
    
    init(polyline: PolylineData) {
        self.storage = .polylineData(Bindable(polyline))
    }
    
    init(polyline: Binding<WorkingPolyline>) {
        self.storage = .workingPolyline(polyline)
    }
    
    var body: some View {
        Form {
            PolylineMapPreview(polyline: storage.wrappedValue)
                .id(previewId)
                .frame(height: 260)
                .onChange(of: storage.coordinates.wrappedValue) {
                    previewId = UUID()
                }
            
            TextField("Name this path", text: storage.title)
                .font(.title2.bold())
                .overlay {
                    if storage.title.wrappedValue.isEmpty {
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
                    
                    if !storage.coordinates.wrappedValue.isEmpty {
                        Divider()
                    }
                    
                    ForEach(Array(storage.coordinates.wrappedValue.enumerated()), id: \.1.id) { (index, coordinate) in
                        Spacer()
                            .frame(height: 10)
                        
                        GridRow {
                            Text("\(index + 1)")
                            
                            let latBinding = Binding {
                                coordinate.latitude
                            } set: {
                                storage.coordinates.wrappedValue[index].latitude = $0
                            }
                            
                            let lngBinding = Binding {
                                coordinate.longitude
                            } set: {
                                storage.coordinates.wrappedValue[index].longitude = $0
                            }
                            
                            TextField("", value: latBinding, format: .number)
                            
                            TextField("", value: lngBinding, format: .number)
                        }
                        .textFieldStyle(.roundedBorder)
                        
                        if index != storage.coordinates.wrappedValue.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .overlay {
                if storage.coordinates.wrappedValue.isEmpty {
                    Color.red.opacity(0.2)
                        .padding(-40)
                }
            }
            
            DisclosureGroup("Notes") {
                HStack(spacing: 0) {
                    Divider()
                    
                    TextEditor(text: storage.userDescription)
                        .frame(height: 200)
                }
            }
        }
        .navigationTitle(storage.title.wrappedValue)
    }
}

#Preview {
    @Previewable @State var polyline = WorkingPolyline.example
    
    PolylineDetailView(polyline: $polyline)
}
