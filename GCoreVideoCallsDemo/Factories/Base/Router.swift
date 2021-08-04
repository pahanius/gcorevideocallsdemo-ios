
import UIKit

typealias RouterCompletions = [UIViewController : () -> Void]

final class Router: NSObject {
    
    // MARK: - Private variables
    private weak var rootController: UINavigationController?
    
    private var completions: RouterCompletions
    
    init(rootController: UINavigationController) {
        self.rootController = rootController
        completions = [:]
    }
    
    var toPresent: UIViewController? {
        rootController
    }
}

// MARK: - Private methods
private extension Router {
    func runCompletion(for controller: UIViewController) {
        guard let completion = completions[controller] else {
            return
        }
        completion()
        completions.removeValue(forKey: controller)
    }
}

// MARK: - Routable
extension Router: Routable {
    func present(_ module: Presentable?) {
        present(module, animated: true)
    }
    
    func present(_ module: Presentable?, animated: Bool) {
        guard let controller = module?.toPresent else {
            return
        }
        rootController?.present(controller, animated: animated, completion: nil)
    }
    
    func present(_ module: Presentable?, animated: Bool, completion: @escaping (() -> Void)) {
        guard let controller = module?.toPresent else {
            return
        }
        rootController?.present(controller, animated: animated, completion: completion)
    }
    
    func presentOverfullscreen(_ module: Presentable?, animated: Bool) {
        guard let controller = module?.toPresent else {
            return
        }
        controller.modalPresentationStyle = .overFullScreen
        rootController?.present(controller, animated: animated, completion: nil)
    }
    
    func push(_ module: Presentable?) {
        push(module, animated: true)
    }
    
    func push(_ module: Presentable?, animated: Bool) {
        push(module, animated: animated, completion: nil)
    }
    
    func push(_ module: Presentable?, animated: Bool, completion: (() -> Void)?) {
        guard
            let controller = module?.toPresent,
            !(controller is UINavigationController)
            else { assertionFailure("⚠️ Deprecated push UINavigationController."); return }
        
        if let completion = completion {
            completions[controller] = completion
        }
        rootController?.pushViewController(controller, animated: animated)
    }
    
    func popModule() {
        popModule(animated: true)
    }
    
    func popModule(animated: Bool) {
        if let controller = rootController?.popViewController(animated: animated) {
            runCompletion(for: controller)
        }
    }
    
    func dismissModule() {
        dismissModule(animated: true, completion: nil)
    }
    
    func dismissModule(animated: Bool, completion: (() -> Void)?) {
        rootController?.dismiss(animated: animated, completion: completion)
    }
    
    func setRootModule(_ module: Presentable?, rootAnimated: Bool) {
        setRootModule(module, hideNavigationBar: false, rootAnimated: rootAnimated)
    }
    
    func setRootModule(_ module: Presentable?, hideNavigationBar: Bool, rootAnimated: Bool) {
        guard let controller = module?.toPresent else {
            return
        }
        
        if rootAnimated,
           let snapshot: UIView = (
            (UIApplication.shared.delegate as? AppDelegate)?
                .window?
                .snapshotView(afterScreenUpdates: true)
           ) {
            let desiredViewController = controller
            desiredViewController.view.addSubview(snapshot)
            
            rootController?.setViewControllers([desiredViewController], animated: false)
            
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    snapshot.layer.opacity = 0
                }, completion: { _ in
                    snapshot.removeFromSuperview()
                }
            )
        } else {
            rootController?.setViewControllers([controller], animated: false)
        }
        
        rootController?.isNavigationBarHidden = hideNavigationBar
        _ = rootController?.view
    }
    
    func popToRootModule(animated: Bool) {
        if let controllers = rootController?.popToRootViewController(animated: animated) {
            controllers.forEach { controller in
                runCompletion(for: controller)
            }
        }
    }
    
    func presentPopover(_ module: Presentable?,
                        animated: Bool,
                        inputPopover: InputPopover,
                        origin: Presentable?,
                        completion: @escaping (() -> Void)) {
        guard let controller = module?.toPresent else {
            return
        }
        
        controller.modalPresentationStyle = .popover
        controller.popoverPresentationController?.sourceRect = inputPopover.sourceRect
        controller.preferredContentSize = inputPopover.preferredContentSize
        controller.popoverPresentationController?.delegate = inputPopover.delegate
        controller.popoverPresentationController?.sourceView = inputPopover.sourceView
        controller.popoverPresentationController?
            .permittedArrowDirections = inputPopover.permittedArrowDirections
        controller.popoverPresentationController?.backgroundColor =
            inputPopover.backgroundColor
        
        if let origin = origin {
            origin.toPresent?.present(controller, animated: animated, completion: nil)
        } else {
            rootController?.present(controller, animated: animated, completion: nil)
        }
    }
    
    func dismissModule(origin: Presentable?, animated: Bool, completion: CompletionBlock?) {
        guard let vc = origin?.toPresent else {
            print("Origin view is nil")
            return
        }
        vc.dismiss(animated: animated, completion: completion)
    }
}
