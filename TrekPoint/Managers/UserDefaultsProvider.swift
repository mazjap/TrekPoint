import Foundation
import Dependencies

protocol UserDefaultsProvider {
    func bool(forKey: String) -> Bool
    func optionalBool(forKey: String) -> Bool?
    func set(_ value: Any?, forKey: String)
    func string(forKey: String) -> String?
    func removeObject(forKey: String)
}

extension UserDefaults: UserDefaultsProvider {
    func optionalBool(forKey key: String) -> Bool? {
        object(forKey: key) as? Bool
    }
}

enum UserDefaultsProviderKey: DependencyKey {
    static let liveValue: any UserDefaultsProvider = UserDefaults.standard
}

extension DependencyValues {
    var userDefaultsProvider: any UserDefaultsProvider {
        get { self[UserDefaultsProviderKey.self] }
        set { self[UserDefaultsProviderKey.self] = newValue }
    }
}
