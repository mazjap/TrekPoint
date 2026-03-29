import Foundation
import Dependencies

@Observable
class AppSettings {
    @ObservationIgnored private var userDefaults: UserDefaultsProvider
    
    var mapStyle: MapStyleSetting {
        didSet { userDefaults.set(mapStyle.rawValue, forKey: "map_style") }
    }
    
    var distanceUnit: DistanceUnit {
        didSet { userDefaults.set(distanceUnit.rawValue, forKey: "distance_unit") }
    }
    
    var gpsAccuracy: GPSAccuracyMode {
        didSet { userDefaults.set(gpsAccuracy.rawValue, forKey: "gps_accuracy") }
    }
    
    var isTerrainEnabled: Bool {
        didSet { userDefaults.set(isTerrainEnabled, forKey: "terrain_enabled") }
    }
    
    var isContourEnabled: Bool {
        didSet { userDefaults.set(isContourEnabled, forKey: "contour_enabled") }
    }
    
    init() {
        @Dependency(\.userDefaultsProvider) var userDefaults
        self.userDefaults = userDefaults
        self.mapStyle = MapStyleSetting(rawValue: userDefaults.string(forKey: "map_style") ?? "") ?? .hybrid
        self.distanceUnit = DistanceUnit(rawValue: userDefaults.string(forKey: "distance_unit") ?? "") ?? Self.standardDistanceUnitInLocale
        self.gpsAccuracy = GPSAccuracyMode(rawValue: userDefaults.string(forKey: "gps_accuracy") ?? "") ?? .balanced
        self.isTerrainEnabled = userDefaults.optionalBool(forKey: "terrain_enabled") ?? true
        self.isContourEnabled = userDefaults.optionalBool(forKey: "contour_enabled") ?? false
    }
    
    static private let standardDistanceUnitInLocale: DistanceUnit = Locale.current.measurementSystem == .metric ? .metric : .imperial
}

enum AppSettingsKey: DependencyKey {
    static let liveValue = AppSettings()
}

extension DependencyValues {
    var appSettings: AppSettings {
        get { self[AppSettingsKey.self] }
        set { self[AppSettingsKey.self] = newValue }
    }
}
