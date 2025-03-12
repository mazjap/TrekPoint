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
    @Binding private var showSheet: Bool
    
    init(showSheet: Binding<Bool>) {
        self._showSheet = showSheet
    }

    var body: some View {
        NavigationStack {
            DetailedMapView(showSheet: $showSheet, toastReasons: $toastReasons)
                .navigationTitle("Map")
                .toolbar(.hidden, for: .navigationBar)
                .toolbarBackground(.thinMaterial, for: .navigationBar, .tabBar)
        }
    }
}

#Preview {
    ContentView(showSheet: .constant(true))
        .modelContainer(for: CurrentModelVersion.models, inMemory: true)
}
