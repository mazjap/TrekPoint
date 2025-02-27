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
                
//                ForEach($coordinates) { $coordinate in
//                    LabeledContent("Latitude") {
//                        TextField("", value: $coordinate.latitude, format: .number)
//                    }
//                    
//                    LabeledContent("Longitude") {
//                        TextField("", value: $coordinate.longitude, format: .number)
//                    }
//                }
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
