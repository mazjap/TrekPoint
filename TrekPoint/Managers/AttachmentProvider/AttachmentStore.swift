import Foundation
import UIKit
import SwiftUI

enum AttachmentError: Error {
    case fileNotFound
    case imageCompressionFailed
    case iAskedFileManagerAndFileManagerSaidNo
    case fileWriteFailed(Error)
    case fileReadFailed(Error)
}

protocol FileManagerProvider {
    var documentDirectory: URL { get }
    
    func fileExists(atPath: String) -> Bool
    func createDirectory(at url: URL, withIntermediateDirectories: Bool, attributes: [FileAttributeKey : Any]?) throws
    func createFile(atPath path: String, contents: Data?, attributes: [FileAttributeKey : Any]?) -> Bool
    func copyItem(at source: URL, to destination: URL) throws
    func setAttributes(_ attributes: [FileAttributeKey : Any], ofItemAtPath path: String) throws
    func removeItem(at url: URL) throws
}

extension FileManager: FileManagerProvider {
    var documentDirectory: URL {
        urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

class AttachmentStore: AttachmentProvider {
    private let fileManager: FileManagerProvider
    private let attachmentsDirectory: URL
    
    init(fileManager: FileManagerProvider = FileManager.default) {
        self.fileManager = fileManager
        
        let documentsDirectory = fileManager.documentDirectory
        let attachmentsDirectory = documentsDirectory.appendingPathComponent("Attachments", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: attachmentsDirectory.path()) {
            do {
                try fileManager.createDirectory(at: attachmentsDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Failed to create Attachments directory: \(error)")
            }
        }
        
        self.attachmentsDirectory = attachmentsDirectory
    }
    
    func storeImage(_ image: UIImage) throws -> Attachment {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw AttachmentError.imageCompressionFailed
        }
        
        let attachment = Attachment(type: .image)
        let fileURL = attachmentsDirectory.appendingPathComponent(attachment.fileName)
        
        if !fileManager.createFile(atPath: fileURL.path(), contents: data, attributes: [.protectionKey : FileProtectionType.complete]) {
            throw AttachmentError.iAskedFileManagerAndFileManagerSaidNo
        }
        
        return attachment
    }
    
    func storeVideo(thatExistsAtURL tempURL: URL) throws -> Attachment {
        let attachment = Attachment(type: .video)
        let destinationURL = attachmentsDirectory.appendingPathComponent(attachment.fileName)
        
        do {
            // Copy from the source to new permanent location
            try fileManager.copyItem(at: tempURL, to: destinationURL)
            try fileManager.setAttributes([.protectionKey : FileProtectionType.complete], ofItemAtPath: destinationURL.path())
            
            return attachment
        } catch {
            throw AttachmentError.fileWriteFailed(error)
        }
    }
    
    func getUrl(for attachment: Attachment) throws -> URL {
        let url = attachmentsDirectory.appendingPathComponent(attachment.fileName)
        
        if fileManager.fileExists(atPath: url.path()) {
            return url
        } else {
            throw AttachmentError.fileNotFound
        }
    }
    
    func delete(_ attachment: Attachment) throws {
        let url = attachmentsDirectory.appendingPathComponent(attachment.fileName)
        
        if fileManager.fileExists(atPath: url.path()) {
            try fileManager.removeItem(at: url)
        } else {
            throw AttachmentError.fileNotFound
        }
    }
    
    func exists(_ attachment: Attachment) -> Bool {
        let url = attachmentsDirectory.appendingPathComponent(attachment.fileName)
        return fileManager.fileExists(atPath: url.path())
    }
}
