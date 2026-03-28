import SwiftUI

extension View {
    @ViewBuilder
    func versionSpecificBackground(in shape: some Shape) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(.regular.tint(Color(.tertiarySystemBackground).opacity(0.5)), in: shape)
        } else {
            self.background {
                shape.fill(Color(.tertiarySystemBackground))
            }
        }
    }
}

extension View {
    @ViewBuilder
    func toolTipVersionSpecificBackground(triangleSize: CGSize, cornerRadius: Double) -> some View {
        self.padding(.trailing, triangleSize.width)
            .versionSpecificBackground(in: RoundedRectangleWithTrailingLeadingFacedTriangle(triangleSize: triangleSize, cornerRadius: cornerRadius))
    }
}
