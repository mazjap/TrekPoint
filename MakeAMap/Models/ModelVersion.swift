import SwiftData

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        ModelVersion1_0_0.self,
    ]
    
    static var stages: [MigrationStage] = []
}

typealias ModelVersion = ModelVersion1_0_0

enum ModelVersion1_0_0: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] = [
        AnnotationData.self,
    ]
}
