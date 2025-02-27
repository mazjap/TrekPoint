import SwiftUI

struct PolylineDetailView: View {
    @Binding private var coordinates: [Coordinate]
    @Binding private var title: String
    
    init(coordinates: Binding<[Coordinate]>, title: Binding<String>) {
        self._coordinates = coordinates
        self._title = title
    }
    
    var body: some View {
        VStack(spacing: 0) {
            MapPreview(feature: .polyline(PolylineData(title: title, coordinates: coordinates)))
                .frame(height: 240)
            
            Form {
                TextField("Name this path", text: $title)
                    .font(.title2.bold())
                
                DisclosureGroup("Coordinates") {
                    
                    Grid(alignment: .leading) {
                        GridRow {
                            Text("#")
                            
                            Text("Latitude:")
                            
                            Text("Longitude:")
                        }
                        
                        ForEach(Array(coordinates.enumerated()), id: \.1.id) { (index, coordinate) in
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
            }
        }
    }
}

#Preview {
    struct PolylineDetailPreview: View {
        @State private var coordinates = PolylineData.example.coordinates
        @State private var title = "This is the title"
        
        var body: some View {
            PolylineDetailView(coordinates: $coordinates, title: $title)
        }
    }
    
    return PolylineDetailPreview()
}
