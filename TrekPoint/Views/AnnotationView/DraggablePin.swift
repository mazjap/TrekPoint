// Adapted from: https://www.youtube.com/watch?v=L2_JRCG6LQo

import SwiftUI

struct DraggablePin: View {
    @State private var translation: CGSize = .zero
    @State private var isActive: Bool = false
    @State private var isJigglingActive: Bool = false
    
    @ScaledMetric(relativeTo: .title) private var iconSize: Double = 48
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private let movementEnabled: Bool
    private let shouldJiggle: Bool
    private let accentColor: Color
    private let fillColor: Color
    private let anchor: UnitPoint
    private let applyNewPosition: (CGPoint) -> Void
    
    init(movementEnabled: Bool, shouldJiggle: Bool, fillColor: Color?, accentColor: Color?, anchor: UnitPoint, applyNewPosition: @escaping (CGPoint) -> Void) {
        self.movementEnabled = movementEnabled
        self.shouldJiggle = shouldJiggle
        self.fillColor = fillColor ?? .white
        self.accentColor = accentColor ?? fillColor ?? .white
        self.anchor = anchor
        self.applyNewPosition = applyNewPosition
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            
            ZStack {
                Image(systemName: "drop.fill")
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.radians(.pi))
                
                ZStack {
                    Image(systemName: "star.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(fillColor)
                    
                    Image(systemName: "star")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, -2)
                }
                .padding(.horizontal, 13)
                .padding(.bottom, 15)
            }
            .rotationEffect(isJigglingActive && shouldJiggle && !isActive && !reduceMotion ? .degrees(isJigglingActive ? 5 : -5) : .zero, anchor: .bottom)
            .animation(isJigglingActive && shouldJiggle && !isActive ? .easeInOut(duration: 0.2).repeatForever(autoreverses: true) : .default, value: isJigglingActive)
            .animation(.snappy, value: isActive)
            .scaleEffect(isActive ? 1.3 : 1, anchor: .center)
            .onChange(of: isActive) {
                let maxX = frame.maxX - frame.minX
                let maxY = frame.maxY - frame.minY
                
                let x = maxX * anchor.x + frame.minX
                let y = maxY * anchor.y + frame.minY
                
                applyNewPosition(CGPoint(x: x, y: y))
                translation = .zero
                
                updateJigglability()
            }
            .onChange(of: shouldJiggle) {
                updateJigglability()
            }
            .task {
                updateJigglability()
            }
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
    
    private func updateJigglability() {
        if shouldJiggle && !isActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isJigglingActive = true
            }
        } else {
            self.isJigglingActive = false
        }
    }
}

import MapKit

#Preview {
    @Previewable @State var isJiggling = true
    let coordinate = CLLocationCoordinate2D.random
    let otherCoordinate: CLLocationCoordinate2D = {
        CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude > 179.5 ? coordinate.longitude - 0.5 : coordinate.longitude + 0.5
        )
    }()
    
    Map {
        Annotation("No Jiggle", coordinate: coordinate, anchor: .bottom) {
            DraggablePin(
                movementEnabled: true,
                shouldJiggle: false,
                fillColor: .white,
                accentColor: .black,
                anchor: .bottom,
                applyNewPosition: {_ in}
            )
            .foregroundStyle(.orange)
        }
        
        Annotation("Jiggle", coordinate: otherCoordinate, anchor: .bottom) {
            DraggablePin(
                movementEnabled: true,
                shouldJiggle: isJiggling,
                fillColor: .yellow,
                accentColor: .white,
                anchor: .bottom,
                applyNewPosition: {_ in}
            )
            .foregroundStyle(.purple, .yellow)
        }
    }
    .overlay(alignment: .bottom) {
        VStack {
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
            
            Spacer()
                .frame(height: 40)
            
            DraggablePin(
                movementEnabled: true,
                shouldJiggle: false,
                fillColor: .yellow,
                accentColor: .blue,
                anchor: .bottom
            ) {_ in}
            .scaleEffect(2)
            .foregroundStyle(.red)
            
            Spacer()
                .frame(height: 20)
        }
        .padding(.bottom, 25)
        .background {
            Color.white
        }
        
    }
    .ignoresSafeArea()
}
