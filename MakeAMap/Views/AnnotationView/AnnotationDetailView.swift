import SwiftUI

struct AnnotationDetailView: View {
    @Binding private var coordinate: Coordinate
    @Binding private var title: String
    
    init(coordinate: Binding<Coordinate>, title: Binding<String>) {
        self._coordinate = coordinate
        self._title = title
    }
    
    var body: some View {
        VStack(spacing: 0) {
            MapPreview(feature: .annotation(AnnotationData(title: title, coordinate: coordinate)))
                .frame(height: 260)
            
            VStack {
                TextField("Name this marker", text: $title)
                    .font(.title2.bold())
                
                LabeledContent("Latitude") {
                    TextField("", value: $coordinate.latitude, format: .number)
                }
                
                LabeledContent("Longitude") {
                    TextField("", value: $coordinate.longitude, format: .number)
                }
                
                Spacer()
            }
            .padding([.horizontal, .top])
            .background {
                Color.white
                    .ignoresSafeArea(edges: .bottom)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: -10)
            }
        }
    }
}

#Preview {
    struct AnnotationDetailPreview: View {
        @State private var coordinate = Coordinate(latitude: 40.05, longitude: -111.67)
        @State private var title = "This is the title"
        
        var body: some View {
            AnnotationDetailView(coordinate: $coordinate, title: $title)
        }
    }
    
    return AnnotationDetailPreview()
}
