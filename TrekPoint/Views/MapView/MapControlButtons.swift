import SwiftUI
import MapKit
import Dependencies

struct MapControlButtons: View {
    @Dependency(\.annotationPersistenceManager) private var annotationManager
    @Dependency(\.polylinePersistenceManager) private var polylineManager
    @Dependency(\.locationTrackingManager) private var locationManager
    @Dependency(\.toastManager) private var toastManager
    
    @Binding private var selectedMapItemTag: MapFeatureTag?
    @Binding private var selectedDetent: PresentationDetent
    
    private let proxy: MapProxy
    private let frame: CGRect
    private let nspace: Namespace.ID
    private let buttonSize: Double
    
    init(selectedMapItemTag: Binding<MapFeatureTag?>, selectedDetent: Binding<PresentationDetent>, proxy: MapProxy, frame: CGRect, nspace: Namespace.ID, buttonSize: Double) {
        self._selectedMapItemTag = selectedMapItemTag
        self._selectedDetent = selectedDetent
        self.proxy = proxy
        self.frame = frame
        self.nspace = nspace
        self.buttonSize = buttonSize
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack {
                VStack(alignment: .leading, spacing: 40) {
                    MapScaleView(scope: nspace)
                    
                    MapCompass(scope: nspace)
                }
                .mapControlVisibility(.visible) // TODO: - Use a setting to determine whether controls are visible
                
                Spacer()
            }
            
            VStack(alignment: .trailing, spacing: 0) {
                let padding = buttonSize / 4
                let activeColor = Color.blue
                let inactiveColor = Color(uiColor: .darkGray)
                let cornerRadius = buttonSize / 3
                
                HStack(spacing: 0) {
                    if annotationManager.isShowingOptions {
                        HStack {
                            Button {
                                do {
                                    try polylineManager.finalizeWorkingPolyline()
                                    
                                    selectedMapItemTag = nil
                                    selectedDetent = .small
                                } catch {
                                    // TODO: - Send to some analytics service
                                    toastManager.commitFeatureCreationError(error)
                                }
                            } label: {
                                Text("Confirm")
                            }
                            
                            Divider()
                            
                            Button {
                                annotationManager.undo()
                            } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward.circle")
                            }
                            .disabled(!annotationManager.canUndo)
                        }
                        .padding(.horizontal)
                        .toolTipVersionSpecificBackground(triangleSize: CGSize(width: 10, height: 20), cornerRadius: cornerRadius)
                    }
                    
                    Button {
                        if annotationManager.workingAnnotation == nil {
                            let midPoint = CGPoint(x: frame.midX, y: frame.midY)
                            
                            guard let coordinate = proxy.convert(
                                midPoint,
                                from: .global
                            ) else {
                                // TODO: - Send to some analytics service
                                toastManager.addBreadForToasting(.somethingWentWrong(.message("Annotation creation was not possible. (\(midPoint) could not be converted to a map coordinate")))
                                
                                return
                            }
                            
                            annotationManager.changeWorkingAnnotationsCoordinate(to: Coordinate(coordinate))
                            selectedMapItemTag = .newFeature
                        } else {
                            annotationManager.clearWorkingAnnotationProgress()
                            selectedMapItemTag = nil
                            selectedDetent = .small
                        }
                    } label: {
                        Image(systemName: "mappin")
                            .resizable()
                            .scaledToFit()
                            .padding(padding)
                            .accessibilityLabel("Create New Marker")
                    }
                    .frame(width: buttonSize)
                    .foregroundStyle(annotationManager.isShowingOptions ? activeColor : inactiveColor)
                    .versionSpecificBackground(in: UnevenRoundedRectangle(topLeadingRadius: cornerRadius, topTrailingRadius: cornerRadius))
                }
                .frame(height: buttonSize)
                
                Divider()
                    .frame(width: buttonSize)
                
                HStack(spacing: 0) {
                    if polylineManager.isShowingOptions && polylineManager.isDrawingPolyline {
                        HStack {
                            Button {
                                do {
                                    _ = try polylineManager.finalizeWorkingPolyline()
                                    
                                    selectedMapItemTag = nil
                                    selectedDetent = .small
                                } catch {
                                    // TODO: - Send to some analytics service
                                    toastManager.commitFeatureCreationError(error)
                                }
                            } label: {
                                Text("Confirm")
                            }
                            
                            Divider()
                            
                            Button {
                                polylineManager.undo()
                            } label: {
                                Label("Undo", systemImage: "arrow.uturn.backward.circle")
                            }
                            .disabled(!polylineManager.canUndo)
                        }
                        .padding(.horizontal)
                        .toolTipVersionSpecificBackground(triangleSize: CGSize(width: 10, height: 20), cornerRadius: cornerRadius)
                    }
                    
                    Button {
                        if polylineManager.workingPolyline != nil {
                            polylineManager.clearWorkingPolylineProgress()
                            selectedMapItemTag = nil
                            selectedDetent = .small
                        } else {
                            polylineManager.startNewWorkingPolyline()
                            selectedMapItemTag = .newFeature
                        }
                    } label: {
                        Image(systemName: polylineManager.isDrawingPolyline ? "hand.draw.fill" : "hand.draw")
                            .resizable()
                            .scaledToFit()
                            .padding(padding)
                            .accessibilityLabel(polylineManager.isDrawingPolyline ? "Stop Drawing Path" : "Draw Path")
                    }
                    .frame(width: buttonSize, height: buttonSize)
                    .foregroundStyle(polylineManager.isDrawingPolyline ? activeColor : inactiveColor)
                    .versionSpecificBackground(in: Rectangle())
                }
                .frame(height: buttonSize)
                
                Divider()
                    .frame(width: buttonSize)
                
                let userLocationShape = if locationManager.isUserLocationActive {
                    AnyShape(Rectangle())
                } else {
                    AnyShape(UnevenRoundedRectangle(bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius))
                        
                }
            
                Button {
                    if locationManager.isUserLocationActive {
                        locationManager.hideUserLocation()
                    } else {
                        locationManager.showUserLocation()
                    }
                } label: {
                    Image(systemName: locationManager.isUserLocationActive ? "location.north.circle.fill" : "location.north.circle")
                        .resizable()
                        .scaledToFit()
                        .padding(padding)
                        .accessibilityLabel((locationManager.isUserLocationActive ? "Hide" : "Show") + " Current Location")
                }
                .frame(width: buttonSize)
                .foregroundStyle(locationManager.isUserLocationActive ? activeColor : inactiveColor)
                .versionSpecificBackground(in: userLocationShape)
                .frame(height: buttonSize)
                
                if locationManager.isUserLocationActive {
                    Divider()
                        .frame(width: buttonSize)
                    
                    HStack(spacing: 0) {
                        if polylineManager.isTrackingPolyline {
                            HStack {
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
                                        do {
                                            _ = try polylineManager.finalizeWorkingPolyline()
                                            
                                            locationManager.stopTracking()
                                        } catch {
                                            print(error)
                                            // Show error toast
                                        }
                                    } label: {
                                        Text("Confirm")
                                    }
                                    .frame(height: buttonSize)
                                    .padding(.horizontal)
                                    .toolTipVersionSpecificBackground(triangleSize: CGSize(width: 10, height: 20), cornerRadius: cornerRadius)
                                }
                            }
                        }
                        
                        Button {
                            if polylineManager.workingPolyline != nil {
                                polylineManager.clearWorkingPolylineProgress()
                                selectedMapItemTag = nil
                                selectedDetent = .small
                                locationManager.stopTracking()
                            } else {
                                polylineManager.startNewLocationTrackedPolyline(withUserCoordinate: locationManager.startTracking())
                                selectedMapItemTag = .newFeature
                            }
                        } label: {
                            Image(systemName: polylineManager.isTrackingPolyline ? "location.north.line.fill" : "location.north.line")
                                .resizable()
                                .scaledToFit()
                                .padding(padding)
                                .accessibilityLabel(polylineManager.isTrackingPolyline ? "Stop Tracking" : "Track My Path")
                        }
                        .frame(width: buttonSize)
                        .foregroundStyle(polylineManager.isTrackingPolyline ? activeColor : inactiveColor)
                        .versionSpecificBackground(in: UnevenRoundedRectangle(bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius))
                    }
                    .frame(height: buttonSize)
                }
            }
            .opacity(selectedDetent == .largeWithoutScaleEffect ? 0 : 1)
            .animation(.easeOut(duration: 0.2), value: selectedDetent)
            .animation(.easeInOut(duration: 0.2), value: locationManager.isUserLocationActive)
        }
        .padding(.horizontal)
    }
}

fileprivate struct RoundedRectangleWithTrailingLeadingFacedTriangle: Shape {
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


fileprivate extension View {
    @ViewBuilder
    func versionSpecificBackground(in shape: some Shape) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(in: shape)
        } else {
            self.background {
                shape.fill(.background)
            }
        }
    }
    
    @ViewBuilder
    func toolTipVersionSpecificBackground(triangleSize: CGSize, cornerRadius: Double) -> some View {
        self.padding(.trailing, triangleSize.width)
            .versionSpecificBackground(in: RoundedRectangleWithTrailingLeadingFacedTriangle(triangleSize: triangleSize, cornerRadius: cornerRadius))
    }
}
