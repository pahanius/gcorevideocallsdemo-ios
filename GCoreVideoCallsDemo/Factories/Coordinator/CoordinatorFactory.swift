
import UIKit

final class CoordinatorFactory {
    private let modulesFactory = ModulesFactory()
}

// MARK: - CoordinatorFactoryProtocol

extension CoordinatorFactory: CoordinatorFactoryProtocol {
    func makeRoomCoordinator(router: Routable) -> Coordinatable & RoomCoordinatorOutput {
        RoomCoordinator(with: modulesFactory, router: router)
    }
}

// MARK: - Private methods

private extension CoordinatorFactory {
    func router(_ navController: UINavigationController?) -> Routable {
        Router(rootController: navigationController(navController))
    }
    
    func navigationController(_ navController: UINavigationController?) -> UINavigationController {
        if let navController = navController {
            return navController
        } else {
            return UINavigationController()
        }
    }
}
