import SwiftUI

fileprivate struct LaunchAnimationState {
    var hOffset: Double = 0
    var vOffset: Double = 0
    var backgroundOpacity: Double = 1
    var elementOpacity: Double = 1
}

fileprivate enum AnimationStep: CaseIterable {
    case bounce
    case moveOffscreen
}

struct LaunchAnimationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var animationState = LaunchAnimationState()
    @Binding private var isAnimationComplete: Bool
    
    private let size: CGSize
    
    init(isAnimationComplete: Binding<Bool>) {
        self._isAnimationComplete = isAnimationComplete
        self.size = UIScreen.current?.bounds.size ?? .zero
    }
    
    var body: some View {
        ZStack {
            Color.launchScreen
                .opacity(animationState.backgroundOpacity)
            
            ZStack {
                Image("MountainLeft")
                    .resizable()
                    .offset(x: -animationState.hOffset, y: animationState.hOffset)
                
                Image("MountainRight")
                    .resizable()
                    .offset(x: animationState.hOffset, y: animationState.hOffset)
                
                Image("Marker")
                    .resizable()
                    .offset(y: animationState.vOffset)
            }
            .scaledToFill()
            .opacity(animationState.elementOpacity)
        }
        .ignoresSafeArea()
        .onAppear {
            if reduceMotion {
                withAnimation(.easeIn(duration: 0.5)) {
                    animationState.backgroundOpacity = 0
                    animationState.elementOpacity = 0
                } completion: {
                    isAnimationComplete = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animationState.vOffset = size.height / 30
                } completion: {
                    withAnimation(.easeInOut(duration: 1)) {
                        animationState.hOffset = size.width
                        animationState.vOffset = -size.height
                        animationState.backgroundOpacity = 0
                    } completion: {
                        isAnimationComplete = true
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isAnimationComplete = false
    @Previewable @State var id = UUID()
    
    ZStack {
        Button("Restart") {
            id = UUID()
        }
        
        LaunchAnimationView(isAnimationComplete: $isAnimationComplete)
            .id(id)
    }
}
