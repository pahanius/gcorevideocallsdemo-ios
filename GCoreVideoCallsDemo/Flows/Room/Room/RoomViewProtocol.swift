
import Foundation

protocol RoomViewProtocol: BaseViewProtocol {
    var onClose: (() -> Void)? { get set }
}
