import SwiftUI
import MapKit

struct AnnotationMapOverlay: MapContent {
    private let annotation: any AnnotationProvider
    private let movementEnabled: Bool
    private let shouldJiggle: Bool
    private let foregroundColor: Color
    private let fillColor: Color?
    private let accentColor: Color?
    private let anchor: UnitPoint
    private let applyNewPosition: (CGPoint) -> Void
    
    init(annotation: some AnnotationProvider, movementEnabled: Bool = true, shouldJiggle: Bool = false, foregroundColor: Color, fillColor: Color? = nil, accentColor: Color? = nil, anchor: UnitPoint = .bottom, applyNewPosition: @escaping (CGPoint) -> Void) {
        self.annotation = annotation
        self.movementEnabled = movementEnabled
        self.shouldJiggle = shouldJiggle
        self.foregroundColor = foregroundColor
        self.fillColor = fillColor
        self.accentColor = accentColor
        self.anchor = anchor
        self.applyNewPosition = applyNewPosition
    }
    
    var body: some MapContent {
        Annotation(annotation.title, coordinate: annotation.clCoordinate, anchor: anchor) {
            DraggablePin(
                movementEnabled: movementEnabled,
                shouldJiggle: shouldJiggle,
                fillColor: fillColor,
                accentColor: accentColor,
                anchor: anchor,
                applyNewPosition: applyNewPosition
            )
            .foregroundStyle(foregroundColor)
            .id(annotation.tag)
        }
        .tag(annotation.tag)
    }
}

#Preview {
    Map {
        AnnotationMapOverlay(annotation: WorkingAnnotation.example, foregroundColor: .orange, applyNewPosition: {_ in})
    }
}
