
import UIKit

protocol Coordinatable: AnyObject {
    func start()
    func startWithPush()
}

extension Coordinatable {
    func startWithPush() {}
}
