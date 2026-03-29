enum MapStyleSetting: String, CaseIterable {
    case standard, satellite, hybrid

    var label: String {
        switch self {
        case .standard: "Standard"
        case .satellite: "Satellite"
        case .hybrid: "Hybrid"
        }
    }

    var icon: String {
        switch self {
        case .standard: "map"
        case .satellite: "globe.americas.fill"
        case .hybrid: "map.fill"
        }
    }
}
