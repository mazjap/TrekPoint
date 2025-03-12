import SwiftUI

fileprivate struct LaunchAnimationState {
    var hOffset: Double = 0
    var vOffset: Double = 0
    var opacity: Double = 1
}

fileprivate enum AnimationStep: CaseIterable {
    case bounce
    case moveOffscreen
}

struct LaunchAnimationView: View {
    @State private var animationState = LaunchAnimationState()
    @State private var isAnimating = false
    @Binding private var isAnimationComplete: Bool
    
    private let size: CGSize
    
    init(isAnimationComplete: Binding<Bool>) {
        self._isAnimationComplete = isAnimationComplete
        self.size = UIScreen.current?.bounds.size ?? .zero
    }
    
    var body: some View {
        ZStack {
            Color.launchScreen
                .opacity(animationState.opacity)
            
            ZStack {
                Image("MountainLeft")
                    .resizable()
                    .offset(x: -animationState.hOffset)
                
                Image("MountainRight")
                    .resizable()
                    .offset(x: animationState.hOffset)
                
                Image("Marker")
                    .resizable()
                    .offset(y: animationState.vOffset)
            }
            .scaledToFill()
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animationState.hOffset = -10
                animationState.vOffset = 5
            } completion: {
                withAnimation(.easeInOut(duration: 1)) {
                    animationState.hOffset = size.width
                    animationState.vOffset = -size.height
                    animationState.opacity = 0
                } completion: {
                    isAnimationComplete = true
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isAnimationComplete = false
    
    LaunchAnimationView(isAnimationComplete: $isAnimationComplete)
}
