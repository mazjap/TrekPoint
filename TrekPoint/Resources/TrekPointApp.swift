import SwiftUI
import Dependencies

@main
struct TrekPointApp: App {
    @Dependency(\.modelContainer) private var modelContainer
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
