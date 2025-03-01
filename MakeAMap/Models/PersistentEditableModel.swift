import protocol SwiftData.PersistentModel
import struct Foundation.Date

protocol PersistentEditableModel: PersistentModel, Hashable {
    var lastEditedAt: Date { get }
}
