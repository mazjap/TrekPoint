import Foundation
import UIKit
import SwiftUI

enum AttachmentError: Error {
    case fileNotFound
    case imageCompressionFailed
    case fileWriteFailed(Error)
    case fileReadFailed(Error)
}

class AttachmentStore {
    private let fileManager: FileManager
    private let attachmentsDirectory: URL
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let attachmentsDirectory = documentsDirectory.appendingPathComponent("Attachments", isDirectory: true)
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: attachmentsDirectory.path) {
            try! fileManager.createDirectory(at: attachmentsDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        self.attachmentsDirectory = attachmentsDirectory
    }
    
    func storeImage(_ image: UIImage) throws -> Attachment {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw AttachmentError.imageCompressionFailed
        }
        
        let attachment = Attachment(type: .image)
        let fileURL = attachmentsDirectory.appendingPathComponent(attachment.fileName)
        
        do {
            try data.write(to: fileURL)
            
            return attachment
        } catch {
            throw AttachmentError.fileWriteFailed(error)
        }
    }
    
    func storeVideo(thatExistsAtURL tempURL: URL) throws -> Attachment {
        let attachment = Attachment(type: .video)
        let destinationURL = attachmentsDirectory.appendingPathComponent(attachment.fileName)
        
        do {
            // Copy from the source to new permanent location
            try fileManager.copyItem(at: tempURL, to: destinationURL)
            
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
