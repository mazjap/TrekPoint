import Foundation

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
    case somethingWentWrong(messageToShowUser: String? = nil, RealReasonForSomethingGoingWrong)

    var id: String {
        switch self {
        case let .annotationCreationError(reason): reason.id
        case let .polylineCreationError(reason): reason.id
        case let .somethingWentWrong(message, reason): (message ?? "") + reason.id
        }
    }
}
