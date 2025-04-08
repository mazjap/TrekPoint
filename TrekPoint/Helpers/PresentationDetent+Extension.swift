import SwiftUI

struct MaxPresentationDetentWithoutScaleEffect: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        context.maxDetentValue - 1
    }
}

extension PresentationDetent {
    static let small = Self.fraction(0.15)
    static let largeWithoutScaleEffect = Self.custom(MaxPresentationDetentWithoutScaleEffect.self)
}

extension Set where Element == PresentationDetent {
    static let defaultMapSheetDetents: Self = [.small, .medium, .largeWithoutScaleEffect]
}
