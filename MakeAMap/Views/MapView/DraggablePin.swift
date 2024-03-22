// Adapted from: https://www.youtube.com/watch?v=L2_JRCG6LQo

import SwiftUI

struct DraggablePin: View {
    @State private var translation: CGSize = .zero
    @State private var isActive: Bool = false
    
    private let movementEnabled: Bool
    private let shouldJiggle: Bool
    private let anchor: UnitPoint
    private let applyNewPosition: (CGPoint) -> Void
    
    init(movementEnabled: Bool = true, shouldJiggle: Bool = false, anchor: UnitPoint = .center, applyNewPosition: @escaping (CGPoint) -> Void) {
        self.movementEnabled = movementEnabled
        self.shouldJiggle = shouldJiggle
        self.anchor = anchor
        self.applyNewPosition = applyNewPosition
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            
            Image(systemName: "mappin.and.ellipse")
                .font(.title)
                .animation(.snappy) { content in
                    content
                        .scaleEffect(isActive ? 1.3 : 1, anchor: .bottom)
                }
                .phaseAnimator([false, true]) { content, state in
                    content
                        .rotationEffect((shouldJiggle && !isActive) ? .degrees(state ? -5 : 5) : .zero, anchor: .bottom)
                } animation: { state in
                    guard shouldJiggle, !isActive else { return nil }
                    
                    let duration = 0.2
                    let animation: Animation
                    
                    if state {
                        animation = .easeOut(duration: duration)
                    } else {
                        animation = .easeIn(duration: duration)
                    }
                    
                    return animation.repeatForever(autoreverses: true)
                }
                .frame(width: frame.width, height: frame.height)
                .onChange(of: isActive) {
                    let maxX = frame.maxX - frame.minX
                    let maxY = frame.maxY - frame.minY
                    
                    let x = maxX * anchor.x + frame.minX
                    let y = maxY * anchor.y + frame.minY
                    
                    applyNewPosition(CGPoint(x: x, y: y))
                    translation = .zero
                }
        }
        .frame(width: 30, height: 30)
        .contentShape(.rect)
        .offset(translation)
        .gesture(LongPressGesture(minimumDuration: 0.15)
            .onEnded {
                if movementEnabled {
                    isActive = $0
                }
            }
            .simultaneously(with: DragGesture(minimumDistance: 0)
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
