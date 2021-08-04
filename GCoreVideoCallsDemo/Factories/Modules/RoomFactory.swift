
import Foundation

protocol RoomFactory {
    func makeJoinView() -> JoinViewProtocol
    func makeRoomView(joinOptions: JoinOptions) -> RoomViewProtocol
}
