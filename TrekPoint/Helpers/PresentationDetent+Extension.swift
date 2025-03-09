import SwiftUI

extension PresentationDetent {
    static let small = Self.fraction(0.15)
    static let largeWithoutScaleEffect = Self.fraction(0.99)
}

extension Set where Element == PresentationDetent {
    static let defaultMapSheetDetents: Self = [.small, .medium, .largeWithoutScaleEffect]
}
