import SwiftUI

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
