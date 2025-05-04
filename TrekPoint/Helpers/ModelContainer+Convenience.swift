import SwiftData
import Dependencies

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

enum ModelContainerKey: DependencyKey {
    static let liveValue: ModelContainer = .shared
    static let previewValue: ModelContainer = .preview
    static let testValue: ModelContainer = .preview
}

extension DependencyValues {
    var modelContainer: ModelContainer {
        get { self[ModelContainerKey.self] }
        set { self[ModelContainerKey.self] = newValue }
    }
}

extension ModelContainer {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(makeConfiguration: { ModelConfiguration(schema: $0, isStoredInMemoryOnly: false) })
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    static let preview: ModelContainer = {
        let container = try! ModelContainer { schema in
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        }
        
        let context = ModelContext(container)
        
        context.insert(AnnotationData.preview)
        context.insert(PolylineData.preview)
        
        try! context.save()
        
        return container
    }()
}

extension AnnotationData {
    static let preview: AnnotationData = {
        AnnotationData(
            title: WorkingAnnotation.example.title,
            userDescription: WorkingAnnotation.example.userDescription,
            coordinate: WorkingAnnotation.example.coordinate,
            attachments: WorkingAnnotation.example.attachments
        )
    }()
}
    

extension PolylineData {
    static let preview: PolylineData = {
        PolylineData(
            title: WorkingPolyline.example.title,
            userDescription: WorkingPolyline.example.userDescription,
            coordinates: WorkingPolyline.example.coordinates,
            isLocationTracked: WorkingPolyline.example.isLocationTracked
        )
    }()
}
