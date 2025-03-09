import SwiftUI
import SwiftData

@main
struct TrekPointApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(CurrentModelVersion.models, version: CurrentModelVersion.versionIdentifier)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appDelegate.locationManager)
                .environment(appDelegate.annotationManager)
                .environment(appDelegate.polylineManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
