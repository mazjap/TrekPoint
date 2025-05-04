import Dependencies
import UIKit

protocol AttachmentProvider {
    func storeImage(_ image: UIImage) throws -> Attachment
    func storeVideo(thatExistsAtURL tempURL: URL) throws -> Attachment
    func getUrl(for attachment: Attachment) throws -> URL
    func delete(_ attachment: Attachment) throws
    func exists(_ attachment: Attachment) -> Bool
}

class TestAttachmentStore: AttachmentProvider {
    var storage = [Attachment : UIImage]()
    
    func storeImage(_ image: UIImage) throws -> Attachment {
        let attachment = Attachment(type: .image)
        
        storage[attachment] = image
        return attachment
    }
    
    func storeVideo(thatExistsAtURL tempURL: URL) throws -> Attachment {
        fatalError()
    }
    
    func getUrl(for attachment: Attachment) throws -> URL {
        fatalError()
    }
    
    func delete(_ attachment: Attachment) throws {
        storage[attachment] = nil
    }
    
    func exists(_ attachment: Attachment) -> Bool {
        storage[attachment] != nil
    }
}

enum AttachmentProviderKey: DependencyKey {
    static var liveValue: any AttachmentProvider { AttachmentStore() }
    static var testValue: any AttachmentProvider { TestAttachmentStore() }
}

extension DependencyValues {
    var attachmentStore: any AttachmentProvider {
        get { self[AttachmentProviderKey.self] }
        set { self[AttachmentProviderKey.self] = newValue }
    }
}
