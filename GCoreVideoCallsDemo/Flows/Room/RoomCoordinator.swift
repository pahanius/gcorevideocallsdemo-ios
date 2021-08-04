
import UIKit

class RoomCoordinator: BaseCoordinator, RoomCoordinatorOutput {
    var finishFlow: CompletionBlock?
    
    private let factory: RoomFactory
    private let router: Routable
    
    init(with factory: RoomFactory, router: Routable) {
        self.factory = factory
        self.router = router
    }
}

// MARK: - Coordinatable

// swiftlint:disable all
extension RoomCoordinator: Coordinatable {
    
    func start() {
        performJoinView()
    }
    
    func performJoinView() {
        let view = factory.makeJoinView()
        view.onJoin = { [weak self] joinOptions in
            self?.showRoomView(joinOptions)
        }
        
        router.setRootModule(view, hideNavigationBar: true, rootAnimated: false)
    }
    
    func showRoomView(_ joinOptions: JoinOptions) {
        let view = factory.makeRoomView(joinOptions: joinOptions)
        view.onClose = { [weak self] in
            self?.router.dismissModule()
        }
        
        router.presentOverfullscreen(view, animated: true)
    }
}
