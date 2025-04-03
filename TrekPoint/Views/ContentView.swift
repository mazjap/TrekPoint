import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var toastManager = ToastManager()
    @Binding private var showSheet: Bool
    
    init(showSheet: Binding<Bool>) {
        self._showSheet = showSheet
    }

    var body: some View {
        NavigationStack {
            DetailedMapView(showSheet: $showSheet, toastManager: toastManager)
                .navigationTitle("Map")
                .toolbar(.hidden, for: .navigationBar)
                .toolbarBackground(.thinMaterial, for: .navigationBar, .tabBar)
        }
    }
}

#Preview {
    ContentView(showSheet: .constant(true))
        .modelContainer(for: CurrentModelVersion.models, inMemory: true)
}
