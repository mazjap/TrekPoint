import protocol SwiftData.PersistentModel
import struct Foundation.Date

protocol PersistentEditableModel: PersistentModel {
    var lastEditedAt: Date { get }
}
