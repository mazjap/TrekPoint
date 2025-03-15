import Foundation
import UIKit
import SwiftUI

class AttachmentStore: Observable {
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
    
    func storeImage(_ image: UIImage) -> Attachment? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let attachment = Attachment(type: .image)
        let fileURL = attachmentsDirectory.appendingPathComponent(attachment.fileName)
        
        do {
            try data.write(to: fileURL)
            
            return attachment
        } catch {
            return nil
        }
    }
    
    func storeVideo(thatExistsAtURL tempURL: URL) -> Attachment? {
        let attachment = Attachment(type: .video)
        let destinationURL = attachmentsDirectory.appendingPathComponent(attachment.fileName)
        
        do {
            // Copy from the source to our permanent location
            try fileManager.copyItem(at: tempURL, to: destinationURL)
            
            return attachment
        } catch {
            return nil
        }
    }
    
    func resolveURL(for attachment: Attachment) -> URL? {
        // Create url from document directory and attachment id + type
        let url = attachmentsDirectory.appendingPathComponent(attachment.fileName)
        
        if fileManager.fileExists(atPath: url.path()) {
            return url
        } else {
            // TODO: - Show message/delete attachment/alert caller
            return nil
        }
    }
    
    func deleteAttachment(_ attachment: Attachment) {
        if let resolvedURL = resolveURL(for: attachment) {
            try? fileManager.removeItem(at: resolvedURL)
        }
    }
}
