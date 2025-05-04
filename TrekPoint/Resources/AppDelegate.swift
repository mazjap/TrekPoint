import UIKit
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate {
    let locationManager: LocationTrackingManager
    let annotationManager: AnnotationPersistenceManager
    let polylineManager: PolylinePersistenceManager
    
    override init() {
        self.locationManager = LocationTrackingManager()
        self.annotationManager = AnnotationPersistenceManager()
        self.polylineManager = PolylinePersistenceManager()
        
        super.init()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Check if an ongoing tracking session exists
        if let trackingID = locationManager.checkForPendingTracks() {
            // Restore the tracking state
            NotificationCenter.default.post(
                name: .restoreTrackingSession,
                object: nil,
                userInfo: ["trackingID" : trackingID]
            )
        }
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        if locationManager.isTracking {
            // TODO: - Use polyline manager to store working polyline for user to decide what to do with next app launch
        }
    }
}
