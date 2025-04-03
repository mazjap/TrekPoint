import SwiftData

// TODO: - 2. Update typealias to new version here:
typealias CurrentModelVersion = ModelInformation.ModelVersion1_1_0

enum ModelInformation {
    static let currentSchema = Schema(CurrentModelVersion.models, version: CurrentModelVersion.versionIdentifier)
    
    enum MigrationPlan: SchemaMigrationPlan {
        // TODO: - 3. Add new version here:
        static var schemas: [any VersionedSchema.Type] = [
            ModelVersion1_0_0.self,
            ModelVersion1_1_0.self
        ]
        
        // TODO: - 4. Add migration plan here:
        static var stages: [MigrationStage] = [
            .lightweight(fromVersion: ModelVersion1_0_0.self, toVersion: ModelVersion1_1_0.self)
        ]
    }
    
    // TODO: - 1. Add new enum verison here:
    enum ModelVersion1_1_0: VersionedSchema {
        static let versionIdentifier = Schema.Version(1, 1, 0)
        
        static var models: [any PersistentModel.Type] = [
            AnnotationData.self,
            PolylineData.self,
            PendingTrackingLocation.self
        ]
    }
    
    enum ModelVersion1_0_0: VersionedSchema {
        static let versionIdentifier = Schema.Version(1, 0, 0)
        
        static var models: [any PersistentModel.Type] = [
            AnnotationData.self,
            PolylineData.self
        ]
    }
}
