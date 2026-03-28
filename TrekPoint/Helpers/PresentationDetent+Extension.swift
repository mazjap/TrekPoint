import SwiftUI

struct MaxPresentationDetentWithoutScaleEffect: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        context.maxDetentValue - 1
    }
}

extension PresentationDetent {
    static let smallDetentHeight: Double = 68
    
    static let tpSmall = if #available(iOS 26, *) {
        Self.height(smallDetentHeight)
    } else {
        Self.fraction(0.15)
    }
    
    static let tpMedium: Self = .fraction(0.45)
    
    static let tpLarge = if #available(iOS 26, *) {
        Self.large
    } else {
        // On older versions of iOS (18 and below), there is a scale affect that this workaround avoids
        Self.custom(MaxPresentationDetentWithoutScaleEffect.self)
    }
}

extension Set where Element == PresentationDetent {
    static let defaultMapSheetDetents: Self = [.tpSmall, .tpMedium, .tpLarge]
}
