import Foundation
import OSLog

enum RealReasonForSomethingGoingWrong {
    case error(Error)
    case message(String)
}

enum ToastReason {
    case annotationCreationError(AnnotationFinalizationError)
    case polylineCreationError(PolylineFinalizationError)
    case somethingWentWrong(RealReasonForSomethingGoingWrong)
    
}

@Observable
class ToastManager {
    var reasons = [ToastReason]()
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
