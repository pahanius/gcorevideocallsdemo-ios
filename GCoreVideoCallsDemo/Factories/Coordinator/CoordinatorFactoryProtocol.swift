
import UIKit

protocol CoordinatorFactoryProtocol {
    func makeRoomCoordinator(router: Routable)
    -> Coordinatable & RoomCoordinatorOutput
}
