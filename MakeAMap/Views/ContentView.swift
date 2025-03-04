import SwiftUI
import SwiftData

enum RealReasonForSomethingGoingWrong {
    case error(Error)
    case message(String)
}

enum ToastReason {
    case annotationCreationError(AnnotationFinalizationError)
    case polylineCreationError(PolylineFinalizationError)
    case somethingWentWrong(RealReasonForSomethingGoingWrong)
}

struct ContentView: View {
    @State private var toastReasons = [ToastReason]()

    var body: some View {
        NavigationStack {
            DetailedMapView(toastReasons: $toastReasons)
                .navigationTitle("Map")
                .toolbar(.hidden, for: .navigationBar)
                .toolbarBackground(.thinMaterial, for: .navigationBar, .tabBar)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: CurrentModelVersion.models, inMemory: true)
}
