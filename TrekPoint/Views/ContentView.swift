import SwiftUI
import SwiftData
import Dependencies

struct ContentView: View {
    @Binding private var showSheet: Bool
    
    init(showSheet: Binding<Bool>) {
        self._showSheet = showSheet
    }

    var body: some View {
        NavigationStack {
            DetailedMapView(showSheet: $showSheet)
                .navigationTitle("Map")
                .toolbar(.hidden, for: .navigationBar)
                .toolbarBackground(.thinMaterial, for: .navigationBar, .tabBar)
        }
    }
}

#Preview {
    @Dependency(\.modelContainer) var modelContainer
    
    ContentView(showSheet: .constant(true))
        .modelContainer(modelContainer)
}
