import SwiftUI
import SwiftData
import Dependencies

struct ContentView: View {
    @State private var isAnimationComplete = false

    var body: some View {
        NavigationStack {
            DetailedMapView(canInitiallyShowSheet: isAnimationComplete)
                .navigationTitle("Map")
                .toolbar(.hidden, for: .navigationBar)
                .toolbarBackground(.thinMaterial, for: .navigationBar, .tabBar)
        }
        .overlay {
            LaunchAnimationView(isAnimationComplete: $isAnimationComplete)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    @Dependency(\.modelContainer) var modelContainer
    
    ContentView()
        .modelContainer(modelContainer)
}
