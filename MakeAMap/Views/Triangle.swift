import SwiftUI

enum Face {
    case top
    case trailing
    case bottom
    case leading
}

struct Triangle: Shape {
    let faceAlignment: Face
    
    init(faceAlignment: Face = .bottom) {
        self.faceAlignment = faceAlignment
    }
    
    func path(in rect: CGRect) -> Path {
        let corner1: CGPoint
        let corner2: CGPoint
        let corner3: CGPoint
        
        switch faceAlignment {
        case .top:
            corner1 = CGPoint(x: rect.midX, y: rect.maxY)
            corner2 = CGPoint(x: rect.maxX, y: rect.minY)
            corner3 = CGPoint(x: rect.minX, y: rect.minY)
        case .trailing:
            corner1 = CGPoint(x: rect.minX, y: rect.midY)
            corner2 = CGPoint(x: rect.maxX, y: rect.minY)
            corner3 = CGPoint(x: rect.maxX, y: rect.maxY)
        case .bottom:
            corner1 = CGPoint(x: rect.midX, y: rect.minY)
            corner2 = CGPoint(x: rect.minX, y: rect.maxY)
            corner3 = CGPoint(x: rect.maxX, y: rect.maxY)
        case .leading:
            corner1 = CGPoint(x: rect.maxX, y: rect.midY)
            corner2 = rect.origin
            corner3 = CGPoint(x: rect.minX, y: rect.maxY)
        }
        
        var path = Path()
        
        path.move(to: corner1)
        path.addLine(to: corner2)
        path.addLine(to: corner3)
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    VStack {
        Triangle(faceAlignment: .top)
            .aspectRatio(1, contentMode: .fit)
            
        Triangle(faceAlignment: .bottom)
            .aspectRatio(1, contentMode: .fit)
        
        HStack {
            Triangle(faceAlignment: .leading)
            
            Triangle(faceAlignment: .trailing)
        }
    }
}
