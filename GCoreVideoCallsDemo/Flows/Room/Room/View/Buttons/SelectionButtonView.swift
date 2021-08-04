
import UIKit

class SelectionButtonView: UIView {
    
    private let button = UIButton(type: .system)
    private let iconImageView = UIImageView()
    
    enum SelectionButtonType {
        case microphone
        case camera
        case switchCamera
    }
    
    var type: SelectionButtonType = .microphone
    
    var isOn: Bool = false {
        didSet {
            updateState()
        }
    }
    
    var stateChanged: ((_ isOn: Bool) -> Void)?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initUI()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.pin
            .all()
        
        iconImageView.pin
            .center()
            .width(28)
            .height(28)
    }
    
    private func initUI() {
        clipsToBounds = true
        layer.cornerRadius = 16
        
        addSubview(button)
        addSubview(iconImageView)
        
        iconImageView.isUserInteractionEnabled = false
                
        button.addTarget(self, action: #selector(onButton), for: .touchUpInside)
        
        updateState()
        
        setNeedsDisplay()
    }
    
    private func updateState() {
        if type == .switchCamera {
            button.backgroundColor = UIColor(rgb: 0x6a6b6a)
            return
        }
        
        button.backgroundColor = isOn ? UIColor(rgb: 0x6ab93d) : UIColor(rgb: 0x2f264a)
        iconImageView.isHighlighted = isOn
    }
    
    @objc private func onButton() {
        isOn = !isOn
        updateState()
        stateChanged?(isOn)
    }
    
    func setType(_ type: SelectionButtonType) {
        self.type = type
        switch type {
        case .microphone:
            iconImageView.image = UIImage(named: "mic_off")
            iconImageView.highlightedImage = UIImage(named: "mic_on")
        case .camera:
            iconImageView.image = UIImage(named: "video_off")
            iconImageView.highlightedImage = UIImage(named: "video_on")
        case .switchCamera:
            iconImageView.image = UIImage(named: "switch_camera")?.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = .white
        }
        
        updateState()
    }
}
