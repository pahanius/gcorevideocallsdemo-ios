
final class ModulesFactory: RoomFactory {
    func makeJoinView() -> JoinViewProtocol {
        let view = JoinViewController.loadFromNib()
        return view
    }
    
    func makeRoomView(joinOptions: JoinOptions) -> RoomViewProtocol {
        let view = RoomViewController.loadFromNib()
        view.configure(joinOptions: joinOptions)
        return view
    }
}
