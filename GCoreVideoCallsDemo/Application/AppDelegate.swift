import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window : UIWindow?
    private lazy var coordinator: Coordinatable = self.makeCoordinator()
    
    func application(_ application: UIApplication,
        didFinishLaunchingWithOptions
        launchOptions: [UIApplication.LaunchOptionsKey : Any]?)
        -> Bool {
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        coordinator.start()
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    func application(
      _ application: UIApplication,
      continue userActivity: NSUserActivity,
      restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return false
        }
        
        if let queryItem = queryItems.first(where: { $0.name == "roomId" }) {
            UserDefaults.standard.setValue(queryItem.value, forKey: "roomId")
            
            NotificationCenter.default.post(name: Notification.Name("roomIdCatched"), object: nil)
        }
        
        return true
    }
}

private
extension AppDelegate {
    func makeCoordinator() -> Coordinatable {
        let navController = UINavigationController()
        
        window?.rootViewController = navController
        
        return AppCoordinator(
            router: Router(rootController: navController),
            factory: CoordinatorFactory()
        )
    }
}
