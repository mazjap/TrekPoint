import SwiftUI
import Dependencies

@main
struct TrekPointApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    @State private var isAnimationComplete = false
    @Dependency(\.modelContainer) private var modelContainer
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(showSheet: $isAnimationComplete)
                    .environment(appDelegate.locationManager)
                    .environment(appDelegate.annotationManager)
                    .environment(appDelegate.polylineManager)
                
                if !isAnimationComplete {
                    LaunchAnimationView(isAnimationComplete: $isAnimationComplete)
                }
            }
        }
        .modelContainer(modelContainer)
    }
}
