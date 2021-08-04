
import Foundation

protocol JoinViewProtocol: BaseViewProtocol {
    var onJoin: ((_ joinOptions: JoinOptions) -> Void)? { get set }
}
