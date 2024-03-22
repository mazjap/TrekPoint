import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var annotations: [AnnotationData]

    var body: some View {
        NavigationStack {
            DetailedMapView()
                .navigationTitle("Map")
                .toolbar(.hidden, for: .navigationBar)
                .toolbarBackground(.thinMaterial, for: .navigationBar, .tabBar)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: AnnotationData.self, inMemory: true)
}
