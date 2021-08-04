
import UIKit

protocol RoomCoordinatorOutput: AnyObject {
    var finishFlow: CompletionBlock? { get set }
}
