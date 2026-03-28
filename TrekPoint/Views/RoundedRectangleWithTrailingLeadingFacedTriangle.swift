import SwiftUI

struct RoundedRectangleWithTrailingLeadingFacedTriangle: Shape {
    let triangleSize: CGSize
    let cornerRadius: Double
    
    func path(in rect: CGRect) -> Path {
        let roundedRectFrame = CGRect(x: rect.minX, y: rect.minY, width: rect.width - triangleSize.width + 1, height: rect.height)
        let roundedRectPath = RoundedRectangle(cornerRadius: cornerRadius).path(in: roundedRectFrame)
        
        let triangleOrigin = CGPoint(x: rect.maxX - triangleSize.width, y: roundedRectFrame.midY - triangleSize.height / 2)
        let triangleFrame = CGRect(origin: triangleOrigin, size: triangleSize)
        let trianglePath = Triangle(faceAlignment: .leading).path(in: triangleFrame)
        
        return roundedRectPath.union(trianglePath)
    }
}
