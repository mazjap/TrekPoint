@testable import TrekPoint
import Testing
import UIKit
import Dependencies

@Suite
struct AttachmentStoreTests {
    let fileManager: TestFileManager
    let store: AttachmentStore
    
    init() {
        // Initialize AttachmentStore directly so that the test
        // value of AttachmentProvider isn't used (TestAttachmentStore)
        self.store = AttachmentStore()
        self.fileManager = store.fileManager as! TestFileManager
    }
    
    func createTestImage() -> UIImage {
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContext(size)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return image
    }
    
    @Test("Store image creates a file with the expected name")
    func storeImageCreatesFile() throws {
        let testImage = createTestImage()
        
        let attachment = try store.storeImage(testImage)
        
        #expect(fileManager.files.count == 1)
        let createdFilePath = fileManager.files.keys.first!
        #expect(createdFilePath.contains(attachment.fileName))
        #expect(attachment.type == .image)
    }
    
    @Test("Store image throws when image compression fails")
    func storeImageThrowsOnCompressionFailure() throws {
        // Image that can't be compressed to JPEG
        let mockImage = UIImage()
        
        do {
            _ = try store.storeImage(mockImage)
            #expect(Bool(false), "Should have thrown an error")
        } catch AttachmentError.imageCompressionFailed {
            // All good here
        } catch {
            #expect(Bool(false), "Unexpected error thrown: \(error)")
        }
    }
    
    @Test("Delete attachment removes the file if it exists")
    func deleteAttachmentRemovesFile() throws {
        let attachment = Attachment(type: .image)
        fileManager.files[fileManager.documentDirectory.appending(path: "Attachments").appending(path: attachment.fileName).path()] = (Data(), [:])
        
        try store.delete(attachment)
        
        #expect(fileManager.removedFilePaths.count == 1)
        let removedItemPath = fileManager.removedFilePaths.first!
        #expect(removedItemPath.contains(attachment.fileName))
    }
    
    @Test("Delete attachment throws if file doesn't exist")
    func deleteAttachmentThrowsIfFileNotFound() {
        let attachment = Attachment(type: .image)
        
        do {
            try store.delete(attachment)
            #expect(Bool(false), "Should have thrown an error")
        } catch AttachmentError.fileNotFound {
            // All good here
        } catch {
            #expect(Bool(false), "Unexpected error thrown: \(error)")
        }
    }
    
    @Test("Store video copies the file and sets attributes")
    func storeVideoCopiesFile() throws {
        let tempURL = URL(string: "/temp/video.mp4")!
        
        let attachment = try store.storeVideo(thatExistsAtURL: tempURL)
        
        #expect(fileManager.copiedItems.count == 1)
        #expect(fileManager.copiedItems.first?.source.path() == tempURL.path())
        #expect(fileManager.copiedItems.first?.destination.path().contains(attachment.fileName) == true)
        #expect(attachment.type == .video)
    }
    
    @Test("Get URL returns correct URL when file exists")
    func getUrlReturnsCorrectURL() throws {
        let attachment = Attachment(type: .image)
        fileManager.files[fileManager.documentDirectory.appending(path: "Attachments").appending(path: attachment.fileName).path()] = (Data(), [:])
        
        let url = try store.getUrl(for: attachment)
        #expect(url.lastPathComponent == attachment.fileName)
    }
    
    @Test("Get URL throws when file doesn't exist")
    func getUrlThrowsWhenFileDoesntExist() {
        let attachment = Attachment(type: .image)
        
        do {
            _ = try store.getUrl(for: attachment)
            #expect(Bool(false), "Should have thrown an error")
        } catch AttachmentError.fileNotFound {
            // All good here
        } catch {
            #expect(Bool(false), "Unexpected error thrown: \(error)")
        }
    }
    
    @Test("Exists returns true when file exists")
    func existsReturnsTrueWhenFileExists() {
        let attachment = Attachment(type: .image)
        fileManager.files[fileManager.documentDirectory.appending(path: "Attachments").appending(path: attachment.fileName).path()] = (Data(), [:])
        
        #expect(store.exists(attachment) == true)
    }

    @Test("Exists returns false when file doesn't exist")
    func existsReturnsFalseWhenFileDoesntExist() {
        let attachment = Attachment(type: .image)
        
        #expect(store.exists(attachment) == false)
    }
}
