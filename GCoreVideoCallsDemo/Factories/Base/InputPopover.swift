
import UIKit

class InputPopover {
    weak var delegate: UIPopoverPresentationControllerDelegate?
    var sourceRect: CGRect
    var preferredContentSize: CGSize
    var sourceView: UIView
    var permittedArrowDirections: UIPopoverArrowDirection
    var backgroundColor: UIColor
    
    init(delegate: UIPopoverPresentationControllerDelegate,
         sourceRect: CGRect,
         preferredContentSize: CGSize,
         sourceView: UIView,
         permittedArrowDirections: UIPopoverArrowDirection,
         backgroundColor: UIColor) {
        self.delegate = delegate
        self.sourceRect = sourceRect
        self.preferredContentSize = preferredContentSize
        self.sourceView = sourceView
        self.permittedArrowDirections = permittedArrowDirections
        self.backgroundColor = backgroundColor
    }
}
