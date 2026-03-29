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
