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
            if !isAnimationComplete {
                LaunchAnimationView(isAnimationComplete: $isAnimationComplete)
                    .ignoresSafeArea()
            }
        }
        #if APP_STORE_PREVIEW_MODE // In Other Swift Flags in the current Target's build settings, change -DAPP_STORE_PREVIEW_MODE_false to -DAPP_STORE_PREVIEW_MODE (remove _false suffix)
        .statusBarHidden()
        #endif
    }
}

#Preview {
    @Dependency(\.modelContainer) var modelContainer
    
    ContentView()
        .modelContainer(modelContainer)
}
