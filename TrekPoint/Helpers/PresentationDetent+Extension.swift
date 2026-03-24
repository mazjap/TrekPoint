import SwiftUI

struct MaxPresentationDetentWithoutScaleEffect: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        context.maxDetentValue - 1
    }
}

extension PresentationDetent {
    static let smallDetentHeight: Double = 68
    
    static let small = if #available(iOS 26, *) {
        Self.height(smallDetentHeight)
    } else {
        Self.fraction(0.15)
    }
    
    static let largeWithoutScaleEffect = if #available(iOS 26, *) {
        Self.large
    } else {
        Self.custom(MaxPresentationDetentWithoutScaleEffect.self)
    }
}

extension Set where Element == PresentationDetent {
    static let defaultMapSheetDetents: Self = [.small, .medium, .largeWithoutScaleEffect]
}
