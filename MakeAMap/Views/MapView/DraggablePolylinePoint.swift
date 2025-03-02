import SwiftUI

struct DraggablePolylinePoint: View {
    @ScaledMetric(relativeTo: .title) private var iconSize: Double = 32
    
    @State private var translation: CGSize = .zero
    @State private var isActive = false
    
    private let movementEnabled: Bool
    private let fillColor: Color
    private let anchor: UnitPoint
    private let applyNewPosition: (CGPoint) -> Void
    
    init(movementEnabled: Bool = true, fillColor: Color? = nil, anchor: UnitPoint = .bottom, applyNewPosition: @escaping (CGPoint) -> Void) {
        self.movementEnabled = movementEnabled
        self.fillColor = fillColor ?? .blue
        self.anchor = anchor
        self.applyNewPosition = applyNewPosition
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            
            Image(systemName: "mappin")
                .resizable()
                .scaledToFit()
                .foregroundStyle(fillColor)
                .animation(.snappy, value: isActive)
                .scaleEffect(isActive ? 1.3 : 1, anchor: .center)
                .onChange(of: isActive) {
                    let maxX = frame.maxX - frame.minX
                    let maxY = frame.maxY - frame.minY
                    
                    let x = maxX * anchor.x + frame.minX
                    let y = maxY * anchor.y + frame.minY
                    
                    applyNewPosition(CGPoint(x: x, y: y))
                    translation = .zero
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(width: iconSize, height: iconSize)
        .contentShape(.rect)
        .offset(translation)
        .gesture(LongPressGesture(minimumDuration: 0.2)
            .onEnded {
                if movementEnabled {
                    isActive = $0
                }
            }
            .sequenced(before: DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if isActive && movementEnabled {
                        translation = value.translation
                    }
                }
                .onEnded { value in
                    if isActive {
                        isActive = false
                    }
                }
            )
        )
    }
}
