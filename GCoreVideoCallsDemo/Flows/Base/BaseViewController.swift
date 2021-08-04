
import UIKit

class BaseViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        initConstraints()
        initListeners()
    }
    
    func initUI() {
    }
    
    func initConstraints() {
    }
    
    func initListeners() {
        
    }
}
