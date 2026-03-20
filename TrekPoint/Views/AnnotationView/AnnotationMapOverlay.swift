import SwiftUI
import MapboxMaps

struct AnnotationMapOverlay: MapContent {
    private let fontSize: Double = 10
    private let annotation: any AnnotationProvider
    private let movementEnabled: Bool
    private let shouldJiggle: Bool
    private let baseColor: Color
    private let categoryColor: Color?
    private let anchor: UnitPoint
    private let applyNewPosition: (CGPoint) -> Void
    private let categoryImageName: String
    
    init(annotation: some AnnotationProvider, movementEnabled: Bool = true, shouldJiggle: Bool = false, baseColor: Color = .orange, categoryColor: Color? = nil, categoryImageName: String, anchor: UnitPoint = .bottom, applyNewPosition: @escaping (CGPoint) -> Void) {
        self.annotation = annotation
        self.movementEnabled = movementEnabled
        self.shouldJiggle = shouldJiggle
        self.baseColor = baseColor
        self.categoryColor = categoryColor
        self.anchor = anchor
        self.applyNewPosition = applyNewPosition
        self.categoryImageName = categoryImageName
    }
    
    var body: some MapContent {
        MapViewAnnotation(coordinate: annotation.clCoordinate) {
            DraggablePin(
                movementEnabled: movementEnabled,
                shouldJiggle: shouldJiggle,
                baseColor: baseColor,
                categoryColor: categoryColor,
                categoryImageName: "star",
                anchor: anchor,
                applyNewPosition: applyNewPosition
            )
        }
        .variableAnchors([.init(anchor: .bottom)])
    }
}

#Preview {
    Map {
        AnnotationMapOverlay(annotation: WorkingAnnotation.example, categoryImageName: "star", applyNewPosition: {_ in})
    }
}
