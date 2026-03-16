import SwiftUI
import MapboxMaps

struct AnnotationMapOverlay: MapContent {
    private let fontSize: Double = 10
    private let annotation: any AnnotationProvider
    private let movementEnabled: Bool
    private let shouldJiggle: Bool
    private let foregroundColor: Color
    private let fillColor: Color?
    private let accentColor: Color?
    private let anchor: UnitPoint
    private let applyNewPosition: (CGPoint) -> Void
    private let onTap: () -> Void
    
    init(annotation: some AnnotationProvider, movementEnabled: Bool = true, shouldJiggle: Bool = false, foregroundColor: Color, fillColor: Color? = nil, accentColor: Color? = nil, anchor: UnitPoint = .bottom, applyNewPosition: @escaping (CGPoint) -> Void, onTap: @escaping () -> Void) {
        self.annotation = annotation
        self.movementEnabled = movementEnabled
        self.shouldJiggle = shouldJiggle
        self.foregroundColor = foregroundColor
        self.fillColor = fillColor
        self.accentColor = accentColor
        self.anchor = anchor
        self.applyNewPosition = applyNewPosition
        self.onTap = onTap
    }
    
    var body: some MapContent {
        MapViewAnnotation(coordinate: annotation.clCoordinate) {
            let verticalSpacing: Double = 4
            VStack(spacing: verticalSpacing) {
                DraggablePin(
                    movementEnabled: movementEnabled,
                    shouldJiggle: shouldJiggle,
                    fillColor: fillColor,
                    accentColor: accentColor,
                    anchor: anchor,
                    applyNewPosition: applyNewPosition
                )
                .foregroundStyle(foregroundColor)
                
                Text(annotation.title)
                    .font(.system(size: fontSize, weight: .bold))
            }
            .offset(y: verticalSpacing + fontSize)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
        }
        .variableAnchors([.init(anchor: .bottom)])
    }
}

#Preview {
    Map {
        AnnotationMapOverlay(annotation: WorkingAnnotation.example, foregroundColor: .orange, applyNewPosition: {_ in}, onTap: {})
    }
}
