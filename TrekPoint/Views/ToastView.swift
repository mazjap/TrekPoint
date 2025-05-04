import SwiftUI
import Dependencies

struct ToastView: View {
    private let bread: ToastReason
    
    init(bread: ToastReason) {
        self.bread = bread
    }
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
            
            switch bread {
            case .annotationCreationError(.emptyTitle), .polylineCreationError(.emptyTitle):
                Text("Missing a title")
            case .annotationCreationError(.noCoordinate):
                VStack(alignment: .leading) {
                    Text("Missing a coordinate")
                    
                    Text("Try dragging the pin to place it on the map.")
                        .font(.body)
                }
            case .annotationCreationError(.noAnnotation):
                Text("Something went wrong")
            case .polylineCreationError(.tooFewCoordinates(let required, let have)):
                VStack(alignment: .leading) {
                    Text("Paths need at least \(required) coordinates")
                    
                    Text("This path currently has \(have) coordinates. Try adding more points to complete the path.")
                        .font(.body)
                }
            case .somethingWentWrong:
                Text("Something went wrong")
            }
        }
        .font(.title3.bold())
        .foregroundStyle(.red)
        .padding()
    }
}

#Preview {
    @Dependency(\.toastManager) var toastManager
    
    VStack(spacing: 40) {
        Spacer()
        
        Text("Send bread to be toasted:")
        
        Button("Just because") {
            toastManager.addBreadForToasting(.somethingWentWrong(.message("Just because")))
            
        }
        
        Button("Annotation didn't have a title") {
            toastManager.addBreadForToasting(.annotationCreationError(.emptyTitle))
        }
        
        Button("Polyline didn't have enough coordinates") {
            toastManager.addBreadForToasting(.polylineCreationError(.tooFewCoordinates(required: 2, have: 1)))
        }
        
        Button("A bunch of reasons") {
            toastManager.addBreadForToasting(.annotationCreationError(.emptyTitle))
            toastManager.addBreadForToasting(.annotationCreationError(.noAnnotation))
            toastManager.addBreadForToasting(.annotationCreationError(.noCoordinate))
            
            toastManager.addBreadForToasting(.polylineCreationError(.emptyTitle))
            toastManager.addBreadForToasting(.polylineCreationError(.tooFewCoordinates(required: 10, have: 8)))
            
            toastManager.addBreadForToasting(.somethingWentWrong(.message("Bad things are happening")))
        }
        
        Spacer()
    }
    .preheatToaster(withLoaf: Bindable(toastManager).reasons, options: .plainToasterStrudel) { bread in
        ToastView(bread: bread)
    }
}
