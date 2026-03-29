import Foundation
import Dependencies
import SwiftUI

enum MapStyleSetting: String, CaseIterable {
    case standard, satellite, hybrid//, topographic

    var label: String {
        switch self {
        case .standard: "Standard"
        case .satellite: "Satellite"
        case .hybrid: "Hybrid"
//        case .topographic: "Topographic"
        }
    }

    var icon: String {
        switch self {
        case .standard: "map"
        case .satellite: "globe.americas.fill"
        case .hybrid: "map.fill"
//        case .topographic: "mountain.2.fill"
        }
    }
}

enum DistanceUnit: String, CaseIterable {
    case imperial, metric

    var label: String {
        switch self {
        case .imperial: "Imperial"
        case .metric: "Metric"
        }
    }

    var sublabel: String {
        switch self {
        case .imperial: "mi, ft"
        case .metric: "km, m"
        }
    }

    var icon: String {
        switch self {
        case .imperial: "flag.fill"
        case .metric: "globe"
        }
    }
}

enum GPSAccuracyMode: String, CaseIterable {
    case performance
    case balanced
    case batterySaver

    var label: String {
        switch self {
        case .performance: "Performance"
        case .balanced: "Balanced"
        case .batterySaver: "Battery Saver"
        }
    }

    var sublabel: String {
        switch self {
        case .performance: "Highest accuracy, increased battery use"
        case .balanced: "Good accuracy, moderate battery use"
        case .batterySaver: "Reduced accuracy, minimal battery use"
        }
    }

    var icon: String {
        switch self {
        case .performance: "location.fill"
        case .balanced: "location"
        case .batterySaver: "battery.50"
        }
    }

    var accentColor: Color {
        switch self {
        case .performance: .orange
        case .balanced: .green
        case .batterySaver: .yellow
        }
    }
}

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
    
    init() {
        @Dependency(\.userDefaultsProvider) var userDefaults
        self.userDefaults = userDefaults
        self.mapStyle = MapStyleSetting(rawValue: userDefaults.string(forKey: "map_style") ?? "") ?? .hybrid
        self.distanceUnit = DistanceUnit(rawValue: userDefaults.string(forKey: "distance_unit") ?? "") ?? .imperial
        self.gpsAccuracy = GPSAccuracyMode(rawValue: userDefaults.string(forKey: "gps_accuracy") ?? "") ?? .balanced
    }
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
