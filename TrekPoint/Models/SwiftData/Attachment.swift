import Foundation

typealias Attachment = CurrentModelVersion.Attachment

// NOTE: - If any changes to Attachment(Type) need to be made, make a new model version
extension ModelInformation.ModelVersion1_1_0 {
    enum AttachmentType: String, Codable {
        case image = "jpg"
        case video = "mp4"
    }
    
    struct Attachment: Codable, Identifiable {
        let type: AttachmentType
        let id: UUID
        let createdAt: Date
        
        init(type: AttachmentType, id: UUID = UUID(), createdAt: Date = .now) {
            self.type = type
            self.id = id
            self.createdAt = createdAt
        }
        
        var fileName: String {
            id.uuidString + "." + type.rawValue
        }
    }
}
