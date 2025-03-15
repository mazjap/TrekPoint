import SwiftUI
import SwiftData

@main
struct TrekPointApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    @State private var isAnimationComplete = false
    
    var sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(makeConfiguration: { ModelConfiguration(schema: $0, isStoredInMemoryOnly: false) })
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(showSheet: $isAnimationComplete)
                    .environment(appDelegate.locationManager)
                    .environment(appDelegate.annotationManager)
                    .environment(appDelegate.polylineManager)
                    .environment(AttachmentStore())
                
                if !isAnimationComplete {
                    LaunchAnimationView(isAnimationComplete: $isAnimationComplete)
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}

extension ModelContainer {
    /// Initializes a new ModelContainer with `ModelInformation.currentSchema` & `ModelInformation.MigrationPlan`.
    /// - Parameter makeConfigurations: A closure that passes in the currentSchema and expects an array of ModelConfiguration as the return type.
    /// - Note: If only one ModelConfiguration is needed, initialize with `ModelContainer(makeConfiguration: (Schema) -> ModelConfiguration)` instead.
    convenience init(makeConfigurations: (Schema) -> [ModelConfiguration]) throws {
        let activeSchema = ModelInformation.currentSchema
        
        try self.init(
            for: activeSchema,
            migrationPlan: ModelInformation.MigrationPlan.self,
            configurations: makeConfigurations(activeSchema)
        )
    }
    
    /// Initializes a new ModelContainer with `ModelInformation.currentSchema` & `ModelInformation.MigrationPlan`.
    /// - Parameter makeConfiguration: A closure that passes in the currentSchema and expects a ModelConfiguration as the return type.
    /// - Note: If only more than one ModelConfiguration is needed, initialize with `ModelContainer(makeConfigurations: (Schema) -> [ModelConfiguration])` instead.
    convenience init(makeConfiguration: (Schema) -> ModelConfiguration) throws {
        try self.init { [makeConfiguration($0)] }
    }
}
