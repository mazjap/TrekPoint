import ComposableArchitecture
import Dependencies
import SwiftUI
import MapKit

@Reducer
struct DetailedMapFeature {
    @ObservableState
    struct State {
        var annotations: [AnnotationData]
        var workingAnnotation: ProtoAnnotation?
        var selectedDetent: PresentationDetent
        var isShowingOptions: Bool
        var isEditingDetails: Bool
        var cameraPosition: MapCameraPosition
        var cameraTransitionTrigger: Bool
        var selectedMapItemTag: String?
        var showUserLocation: Bool {
            didSet {
                UserDefaults.standard.set(showUserLocation, forKey: "is_user_location_active")
            }
        }
        let newAnnotationTag = "annotation in the making"
        
        init(
            annotations: [AnnotationData] = [],
            workingAnnotation: ProtoAnnotation? = nil,
            selectedDetent: PresentationDetent = .small,
            isShowingOptions: Bool = false,
            isEditingDetails: Bool = false,
            cameraPosition: MapCameraPosition = .automatic,
            cameraTransitionTrigger: Bool = false,
            selectedMapItemTag: String? = nil
        ) {
            self.annotations = annotations
            self.workingAnnotation = workingAnnotation
            self.selectedDetent = selectedDetent
            self.isShowingOptions = isShowingOptions
            self.isEditingDetails = isEditingDetails
            self.cameraPosition = cameraPosition
            self.cameraTransitionTrigger = cameraTransitionTrigger
            self.selectedMapItemTag = selectedMapItemTag
            self.showUserLocation = UserDefaults.standard.bool(forKey: "is_user_location_active")
        }
    }

    enum Action {
        case annotationsChanged([AnnotationData])
        case addAnnotation(AnnotationData)
        case deleteAnnotation(AnnotationData)
        case clearNewAnnotationProgress
        case annotationFinalized
        case triggerCameraTransition
        case updateUserLocationStatus(isOn: Bool? = nil)
        case updateNewAnnotationLocation(Coordinate)
        case beginNewAnnotationCreation(Coordinate)
    }
    
    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case let .annotationsChanged(annotations):
                state.annotations = annotations
                return .none
            case let .addAnnotation(annotation):
                annotationProvider.add(annotation)
                return .none
            case let .deleteAnnotation(annotation):
                annotationProvider.delete(annotation)
                return .none
            case .annotationFinalized:
                do {
                    guard let workingAnnotation = state.workingAnnotation else { throw AnnotationFinalizationError.noCoordinate }
                    guard !workingAnnotation.title.isEmpty else { throw AnnotationFinalizationError.emptyTitle }
                    
                    annotationProvider.add(AnnotationData(
                        title: workingAnnotation.title,
                        subtitle: workingAnnotation.subtitle,
                        coordinate: workingAnnotation.coordinate
                    ))
                } catch {
                    // TODO: - Handle errors by:
                    // - Determining if error was `AnnotationFinalizationError` or some SwiftData error and handling accordingly
                    // - Showing toast to user
                }
                
                return .send(.clearNewAnnotationProgress)
            case .clearNewAnnotationProgress:
                state.isShowingOptions = false
                state.isEditingDetails = false
                state.workingAnnotation = nil
                state.selectedMapItemTag = nil
                state.selectedDetent = .small
                
                return .none
            case .triggerCameraTransition:
                state.cameraTransitionTrigger.toggle()
                
                return .none
            case .updateUserLocationStatus(let isOn):
                if let isOn {
                    state.showUserLocation = isOn
                } else {
                    state.showUserLocation.toggle()
                }
                
                return .none
            case .updateNewAnnotationLocation(let coord):
                if state.workingAnnotation == nil {
                    return .send(.beginNewAnnotationCreation(coord))
                }
                
                state.workingAnnotation!.coordinate = coord
                state.selectedMapItemTag = state.newAnnotationTag
                state.isShowingOptions = true
                state.isEditingDetails = true
                
                return .none
            case .beginNewAnnotationCreation(let coord):
                state.workingAnnotation = ProtoAnnotation(coordinate: coord)
                state.isShowingOptions = true
                state.isEditingDetails = true
                state.selectedMapItemTag = state.newAnnotationTag
                
                return .none
            }
        }
    }

    @Dependency(\.annotationProvider) private var annotationProvider
}
