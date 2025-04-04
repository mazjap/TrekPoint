import SwiftData

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

extension ModelContainer {
    static let preview: ModelContainer = {
        let container = try! ModelContainer { schema in
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        }
        
        let context = ModelContext(container)
        
        context.insert(previewPolyline)
        context.insert(previewAnnotation)
        
        return container
    }()
    
    static let previewAnnotation: AnnotationData = {
        AnnotationData(
            title: WorkingAnnotation.example.title,
            userDescription: WorkingAnnotation.example.userDescription,
            coordinate: WorkingAnnotation.example.coordinate,
            attachments: WorkingAnnotation.example.attachments
        )
    }()
    
    static let previewPolyline: PolylineData = {
        PolylineData(
            title: WorkingPolyline.example.title,
            userDescription: WorkingPolyline.example.userDescription,
            coordinates: WorkingPolyline.example.coordinates,
            isLocationTracked: WorkingPolyline.example.isLocationTracked
        )
    }()
}
