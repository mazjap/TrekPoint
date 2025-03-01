enum CameraTrigger: Equatable {
    case geometry(MapFeatureGeometry)
    case userLocation(Bool)
    
    mutating func toggleUserLocation() {
        switch self {
        case let .userLocation(value):
            self = .userLocation(!value)
        default:
            self = .userLocation(true)
        }
    }
}
