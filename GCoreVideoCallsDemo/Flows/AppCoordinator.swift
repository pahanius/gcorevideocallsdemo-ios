
import Foundation

final class AppCoordinator: BaseCoordinator {
    
    private let factory: CoordinatorFactoryProtocol
    private let router: Routable
    
    init(router: Routable, factory: CoordinatorFactory) {
        self.router = router
        self.factory = factory
        
        super.init()
    }
}

// MARK: - Coordinatable

extension AppCoordinator: Coordinatable {
    func start() {
        performRoom()
    }
}

// MARK: - Private methods

private extension AppCoordinator {
    func performRoom() {
        let coordinator = factory.makeRoomCoordinator(router: router)
        coordinator.finishFlow = { [weak self, weak coordinator] in
            guard
                let self = self,
                let coordinator = coordinator
                else { return }
            
            self.start()
            self.removeDependency(coordinator)
        }
        addDependency(coordinator)
        coordinator.start()
    }
}
