// Adapted from: https://www.youtube.com/watch?v=L2_JRCG6LQo

import SwiftUI

struct DraggablePin: View {
    @State private var translation: CGSize = .zero
    @State private var isActive: Bool = false
    
    @ScaledMetric(relativeTo: .title) private var iconSize: Double = 32
    
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
            let isJiggling = (shouldJiggle && !isActive)
            
            Image(systemName: "mappin.and.ellipse")
                .resizable()
                .scaledToFit()
                .phaseAnimator([false, true]) { content, state in
                    content
                        .rotationEffect(isJiggling ? .degrees(state ? -5 : 5) : .zero, anchor: anchor)
                } animation: { state in
                    return .easeInOut(duration: 0.2).repeatForever(autoreverses: true)
                }
                .transaction { transaction in
                    if !isJiggling {
                        transaction.animation = .default
                    }
                }
                .animation(.snappy) { content in
                    content
                        .scaleEffect(isActive ? 1.3 : 1, anchor: anchor)
                }
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

#if DEBUG
import MapKit

#Preview {
    struct PinPreview: View {
        @State private var isJiggling = true
        
        let coordinate = CLLocationCoordinate2D.random
        
        var otherCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude > 179.5 ? coordinate.longitude - 0.5 : coordinate.longitude + 0.5
            )
        }
        
        var body: some View {
            Map {
                Annotation("No Jiggle", coordinate: coordinate, anchor: .bottom) {
                    DraggablePin(
                        shouldJiggle: false,
                        anchor: .bottom,
                        applyNewPosition: {_ in}
                    )
                    .foregroundStyle(.orange)
                }
                
                Annotation("Jiggle", coordinate: otherCoordinate, anchor: .bottom) {
                    DraggablePin(
                        shouldJiggle: isJiggling,
                        anchor: .bottom,
                        applyNewPosition: {_ in}
                    )
                    .foregroundStyle(.purple, .yellow)
                }
            }
            .overlay(alignment: .bottom) {
                HStack {
                    Spacer()
                    
                    Button {
                        isJiggling.toggle()
                        print("is jiggling:", isJiggling)
                    } label: {
                        Text("Toggle Jiggle")
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 25)
                .background {
                    Color.white
                }
            }
            .ignoresSafeArea()
        }
    }
    
    return PinPreview()
}
#endif
