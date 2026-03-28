import SwiftUI
import MapboxMaps
import Dependencies

struct MapControlButtons: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let annotationState: AnnotationButtonState
    let polylineState: PolylineButtonState
    let locationState: LocationButtonState
    let selectedDetent: PresentationDetent
    let proxy: MapProxy
    let nspace: Namespace.ID
    let buttonSize: Double
    let onIntent: (MapButtonIntent) -> Void

    
    private let padding: Double
    private let cornerRadius: Double
    
    private let activeColor = Color.accentColor
    private var inactiveColor: Color {
        if colorScheme == .dark {
            Color(uiColor: .secondaryLabel)
        } else {
            Color.primary
        }
    }
    
    private var userLocationShape: AnyShape {
        if locationState.isActive {
            AnyShape(Rectangle())
        } else {
            AnyShape(UnevenRoundedRectangle(bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius))
        }
    }
    
    init(annotationState: AnnotationButtonState, polylineState: PolylineButtonState, locationState: LocationButtonState, selectedDetent: PresentationDetent, proxy: MapProxy, nspace: Namespace.ID, buttonSize: Double, onIntent: @escaping (MapButtonIntent) -> Void) {
        self.annotationState = annotationState
        self.polylineState = polylineState
        self.locationState = locationState
        self.selectedDetent = selectedDetent
        self.proxy = proxy
        self.nspace = nspace
        self.buttonSize = buttonSize
        self.onIntent = onIntent
        self.padding = buttonSize / 4
        self.cornerRadius = buttonSize / 3
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .trailing, spacing: 0) {
                newAnnotationButton
                
                Divider()
                    .frame(width: buttonSize)
                
                newDrawnPolylineButton
                
                Divider()
                    .frame(width: buttonSize)
                
                locationButton
                
                if locationState.isActive {
                    Divider()
                        .frame(width: buttonSize)
                    
                    locationTrackedPolylineButton
                }
            }
            .opacity(selectedDetent == .largeWithoutScaleEffect ? 0 : 1)
            .animation(.easeOut(duration: 0.2), value: selectedDetent)
            .animation(.easeInOut(duration: 0.2), value: locationState.isActive)
        }
        .padding(.horizontal)
    }
    
    private var newAnnotationButton: some View {
        HStack(spacing: 0) {
            if annotationState.isShowingOptions {
                HStack {
                    Button {
                        onIntent(.confirmAnnotation)
                    } label: {
                        Label("Confirm", systemImage: "checkmark.circle")
                            .frame(maxHeight: .infinity)
                    }
                    
                    Divider()
                    
                    Button {
                        onIntent(.undoAnnotation)
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward.circle")
                            .frame(maxHeight: .infinity)
                    }
                    .disabled(!annotationState.canUndo)
                }
                .padding(.horizontal)
                .toolTipVersionSpecificBackground(triangleSize: CGSize(width: 10, height: 20), cornerRadius: cornerRadius)
            }
            
            Button {
                onIntent(.beginAnnotationCreation)
            } label: {
                Image(systemName: "mappin")
                    .resizable()
                    .scaledToFit()
                    .padding(padding)
                    .accessibilityLabel("Create New Marker")
            }
            .frame(width: buttonSize)
            .foregroundStyle(annotationState.isShowingOptions ? activeColor : inactiveColor)
            .versionSpecificBackground(in: UnevenRoundedRectangle(topLeadingRadius: cornerRadius, topTrailingRadius: cornerRadius))
        }
        .frame(height: buttonSize)
    }
    
    private var newDrawnPolylineButton: some View {
        HStack(spacing: 0) {
            if polylineState.isShowingOptions && polylineState.isDrawing {
                HStack {
                    Button {
                        onIntent(.confirmPolyline)
                    } label: {
                        Label("Confirm", systemImage: "checkmark.circle")
                            .frame(maxHeight: .infinity)
                    }
                    
                    Divider()
                    
                    Button {
                        onIntent(.undoPolyline)
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward.circle")
                            .frame(maxHeight: .infinity)
                    }
                    .disabled(!polylineState.canUndo)
                }
                .padding(.horizontal)
                .toolTipVersionSpecificBackground(triangleSize: CGSize(width: 10, height: 20), cornerRadius: cornerRadius)
            }
            
            Button {
                onIntent(.beginPolylineDrawing)
            } label: {
                Image(systemName: polylineState.isDrawing ? "hand.draw.fill" : "hand.draw")
                    .resizable()
                    .scaledToFit()
                    .padding(padding)
                    .accessibilityLabel(polylineState.isDrawing ? "Stop Drawing Path" : "Draw Path")
            }
            .frame(width: buttonSize, height: buttonSize)
            .foregroundStyle(polylineState.isDrawing ? activeColor : inactiveColor)
            .versionSpecificBackground(in: Rectangle())
        }
        .frame(height: buttonSize)
    }
    
    private var locationButton: some View {
        Button {
            if locationState.isActive {
                onIntent(.hideUserLocation)
            } else {
                onIntent(.showUserLocation)
            }
        } label: {
            Image(systemName: locationState.isActive ? "location.north.circle.fill" : "location.north.circle")
                .resizable()
                .scaledToFit()
                .padding(padding)
                .accessibilityLabel((locationState.isActive ? "Hide" : "Show") + " Current Location")
        }
        .frame(width: buttonSize)
        .foregroundStyle(locationState.isActive ? activeColor : inactiveColor)
        .versionSpecificBackground(in: userLocationShape)
        .frame(height: buttonSize)
    }
    
    private var locationTrackedPolylineButton: some View {
        HStack(spacing: 0) {
            if polylineState.isTracking {
                HStack {
                    // TODO: - Make a button and alert user that their location is being recorded and how to turn it off, if they'd like
                    Text("R")
                        .font(.title)
                        .minimumScaleFactor(0.1)
                        .frame(width: buttonSize / 2, height: buttonSize / 2)
                        .padding(.vertical, 6)
                        .background {
                            Circle()
                                .fill(.red)
                        }
                    
                    HStack(spacing: 0) {
                        Button {
                            onIntent(.confirmTrackedPolyline)
                        } label: {
                            Label("Confirm", systemImage: "checkmark.circle")
                                .frame(maxHeight: .infinity)
                        }
                        .frame(height: buttonSize)
                        .padding(.horizontal)
                        .toolTipVersionSpecificBackground(triangleSize: CGSize(width: 10, height: 20), cornerRadius: cornerRadius)
                    }
                }
            }
            
            Button {
                onIntent(.beginTracking)
            } label: {
                Image(systemName: polylineState.isTracking ? "location.north.line.fill" : "location.north.line")
                    .resizable()
                    .scaledToFit()
                    .padding(padding)
                    .accessibilityLabel(polylineState.isTracking ? "Stop Tracking" : "Track My Path")
            }
            .frame(width: buttonSize)
            .foregroundStyle(polylineState.isTracking ? activeColor : inactiveColor)
            .versionSpecificBackground(in: UnevenRoundedRectangle(bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius))
        }
        .frame(height: buttonSize)
    }
}
