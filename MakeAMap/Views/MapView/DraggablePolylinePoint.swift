import SwiftUI

struct DraggablePolylinePoint: View {
    @ScaledMetric(relativeTo: .title) private var iconSize: Double = 20
    
    @State private var translation: CGSize = .zero
    @State private var isActive = false
    
    private let movementEnabled: Bool
    private let fillColor: Color
    private let anchor: UnitPoint
    private let applyNewPosition: (CGPoint) -> Void
    
    init(movementEnabled: Bool = true, fillColor: Color? = nil, anchor: UnitPoint = .center, applyNewPosition: @escaping (CGPoint) -> Void) {
        self.movementEnabled = movementEnabled
        self.fillColor = fillColor ?? .blue
        self.anchor = anchor
        self.applyNewPosition = applyNewPosition
    }
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .global)
            
            ZStack {
                Circle()
                    .fill(.white)
                    .shadow(radius: 2)
                
                Image(systemName: "circle.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(2)
                    .foregroundStyle(fillColor)
            }
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

import MapKit

#Preview {
    let coordinate = CLLocationCoordinate2D.random
    let otherCoordinate: CLLocationCoordinate2D = {
        CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude > 179.5 ? coordinate.longitude - 0.5 : coordinate.longitude + 0.5
        )
    }()
    
    Map {
        Annotation("No Jiggle", coordinate: coordinate, anchor: .bottom) {
            DraggablePolylinePoint(
                movementEnabled: true,
                fillColor: .green,
                anchor: .center
            ) {_ in}
        }
        
        Annotation("Jiggle", coordinate: otherCoordinate, anchor: .bottom) {
            DraggablePolylinePoint(
                movementEnabled: true,
                fillColor: .red,
                anchor: .center
            ) {_ in}
        }
    }
    .overlay(alignment: .bottom) {
        VStack {
            Spacer()
                .frame(height: 40)
            
            HStack {
                Spacer()
            }
            DraggablePolylinePoint(
                movementEnabled: true,
                fillColor: .yellow,
                anchor: .center
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
