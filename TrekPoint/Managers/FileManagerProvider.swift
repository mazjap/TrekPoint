import Dependencies
import Foundation

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

// TODO: - TestFileManager only mocks the happy path
// I should conditionally allow errors to be thrown and test my assumptions there too
// if I run into issues/want to expand my test suite

class TestFileManager: FileManagerProvider {
    let documentDirectory = URL.temporaryDirectory
    var files = [String : (contents: Data, attributes: [FileAttributeKey : Any])]()
    var removedFilePaths = [String]()
    var copiedItems = [(source: URL, destination: URL)]()
    
    func fileExists(atPath path: String) -> Bool {
        files[path] != nil
    }
    
    func createDirectory(at url: URL, withIntermediateDirectories: Bool, attributes: [FileAttributeKey : Any]?) throws {}
    
    func createFile(atPath path: String, contents: Data?, attributes: [FileAttributeKey : Any]?) -> Bool {
        files[path] = (contents ?? Data(), attributes ?? [:])
        
        return true
    }
    
    func copyItem(at source: URL, to destination: URL) throws {
        files[destination.path()] = files[source.path()]
        copiedItems.append((source, destination))
    }
    
    func setAttributes(_ attributes: [FileAttributeKey : Any], ofItemAtPath path: String) throws {
        files[path]?.attributes = attributes
    }
    
    func removeItem(at url: URL) throws {
        files[url.path()] = nil
        
        removedFilePaths.append(url.path())
    }
}

enum FileManagerProviderKey: DependencyKey {
    static let liveValue: FileManagerProvider = FileManager.default
    static var testValue: FileManagerProvider { TestFileManager() }
}

extension DependencyValues {
    var fileManager: FileManagerProvider {
        get { self[FileManagerProviderKey.self] }
        set { self[FileManagerProviderKey.self] = newValue }
    }
}
