import Foundation
import Dependencies

@Observable
class AppSettings {
    @ObservationIgnored private var userDefaults: UserDefaultsProvider
    
    var mapStyle: MapStyleSetting {
        didSet { userDefaults.set(mapStyle.rawValue, forKey: Self.mapStyleKey) }
    }
    
    var distanceUnit: DistanceUnit {
        didSet { userDefaults.set(distanceUnit.rawValue, forKey: Self.distanceUnitKey) }
    }
    
    var gpsAccuracy: GPSAccuracyMode {
        didSet { userDefaults.set(gpsAccuracy.rawValue, forKey: Self.gpsAccuracyKey) }
    }
    
    var isTerrainEnabled: Bool {
        didSet { userDefaults.set(isTerrainEnabled, forKey: Self.isTerrainEnabledKey) }
    }
    
    var isContourEnabled: Bool {
        didSet { userDefaults.set(isContourEnabled, forKey: Self.isContourEnabledKey) }
    }
    
    var isUserLocationActive: Bool {
        didSet { userDefaults.set(isUserLocationActive, forKey: Self.isUserLocationActiveKey) }
    }
    
    var isTrackingActive: Bool {
        didSet { userDefaults.set(isTrackingActive, forKey: Self.isTrackingActiveKey)}
    }
    
    var activeTrackingId: UUID? {
        didSet { userDefaults.set(activeTrackingId?.uuidString, forKey: Self.activeTrackingIdKey) }
    }
    
    init() {
        @Dependency(\.userDefaultsProvider) var userDefaults
        self.userDefaults = userDefaults
        self.mapStyle = MapStyleSetting(rawValue: userDefaults.string(forKey: Self.mapStyleKey) ?? "") ?? .hybrid
        self.distanceUnit = DistanceUnit(rawValue: userDefaults.string(forKey: Self.distanceUnitKey) ?? "") ?? Self.standardDistanceUnitInLocale
        self.gpsAccuracy = GPSAccuracyMode(rawValue: userDefaults.string(forKey: Self.gpsAccuracyKey) ?? "") ?? .balanced
        self.isTerrainEnabled = userDefaults.optionalBool(forKey: Self.isTerrainEnabledKey) ?? true
        self.isContourEnabled = userDefaults.optionalBool(forKey: Self.isContourEnabledKey) ?? false
        self.isUserLocationActive = userDefaults.optionalBool(forKey: Self.isUserLocationActiveKey) ?? false
        self.isTrackingActive = userDefaults.optionalBool(forKey: Self.isUserLocationActiveKey) ?? false
        self.activeTrackingId = userDefaults.string(forKey: Self.activeTrackingIdKey).flatMap { UUID(uuidString: $0) }
    }
    
    static private let standardDistanceUnitInLocale: DistanceUnit = Locale.current.measurementSystem == .metric ? .metric : .imperial
    
    static private let mapStyleKey = "map_style"
    static private let distanceUnitKey = "distance_unit"
    static private let gpsAccuracyKey = "gps_accuracy"
    static private let isTerrainEnabledKey = "terrain_enabled"
    static private let isContourEnabledKey = "contour_enabled"
    static private let isUserLocationActiveKey = "is_user_location_active"
    static private let isTrackingActiveKey = "is_tracking_active"
    static private let activeTrackingIdKey = "active_tracking_id"
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
