
import Foundation

protocol Routable: Presentable {
    
    func present(_ module: Presentable?)
    func present(_ module: Presentable?, animated: Bool)
    func present(_ module: Presentable?, animated: Bool, completion: @escaping (() -> Void))
    func presentOverfullscreen(_ module: Presentable?, animated: Bool)
    
    func push(_ module: Presentable?)
    func push(_ module: Presentable?, animated: Bool)
    func push(_ module: Presentable?, animated: Bool, completion: CompletionBlock?)
    
    func popModule()
    func popModule(animated: Bool)
    
    func dismissModule()
    func dismissModule(animated: Bool, completion: CompletionBlock?)
    func dismissModule(origin: Presentable?, animated: Bool, completion: CompletionBlock?)
    
    func setRootModule(_ module: Presentable?, rootAnimated: Bool)
    func setRootModule(_ module: Presentable?, hideNavigationBar: Bool, rootAnimated: Bool)
    
    func popToRootModule(animated: Bool)
    
    func presentPopover(_ module: Presentable?,
                        animated: Bool,
                        inputPopover: InputPopover,
                        origin: Presentable?,
                        completion: @escaping (() -> Void)
    )
}
