import Foundation
import OSLog
import Dependencies

enum RealReasonForSomethingGoingWrong: Identifiable {
    case error(Error)
    case message(String)
    
    var id: String {
        switch self {
        case let .error(error): error.localizedDescription
        case let .message(message): message
        }
    }
}

enum ToastReason: Identifiable {
    case annotationCreationError(AnnotationFinalizationError)
    case polylineCreationError(PolylineFinalizationError)
    case somethingWentWrong(RealReasonForSomethingGoingWrong)
    
    var id: String {
        switch self {
        case let .annotationCreationError(reason): reason.id
        case let .polylineCreationError(reason): reason.id
        case let .somethingWentWrong(reason): reason.id
        }
    }
}

enum ToastManagerKey: DependencyKey {
    static let liveValue = ToastManager()
}

extension DependencyValues {
    var toastManager: ToastManager {
        get { self[ToastManagerKey.self] }
        set { self[ToastManagerKey.self] = newValue }
    }
}

@Observable
class ToastManager {
    var reasons = [ToastReason]()
    
    // TODO: - Make a LoggerProvider protocol and make Logger a dependency
    private let logger = Logger(subsystem: "ToastManager", category: "TrekPoint")
    
    func commitFeatureCreationError(_ error: Error) {
        switch error {
        case let error as AnnotationFinalizationError:
            addBreadForToasting(.annotationCreationError(error))
        case let error as PolylineFinalizationError:
            addBreadForToasting(.polylineCreationError(error))
        default:
            addBreadForToasting(.somethingWentWrong(.error(error)))
        }
    }
    
    func addBreadForToasting(_ reason: ToastReason) {
        reasons.append(reason)
        
        // Logger.error expects StringInterpolation with (presumably) CustomStringConvertable. This double interpolation works, but is gross
        logger.error("\("\(reason)")")
    }
}
