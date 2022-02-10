
import UIKit
import GCoreVideoCallsSDK

class JoinViewController: UIViewController, JoinViewProtocol {
    @IBOutlet private weak var roomIdField: UITextField!
    @IBOutlet private weak var nameField: UITextField!
    @IBOutlet private weak var clientHostNameField: UITextField!
    @IBOutlet private weak var joinButton: UIButton!
    @IBOutlet private weak var videoSwitch: UISwitch!
    @IBOutlet private weak var audioSwitch: UISwitch!
    @IBOutlet private weak var moderatorSwitch: UISwitch!
    @IBOutlet private weak var currentVideoView: UIView!
    
    private let captureSession = AVCaptureSession()
    
    var onJoin: ((_ joinOptions: JoinOptions) -> Void)?
    var joinOptions = JoinOptions()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateRoomField), name: Notification.Name("roomIdCatched"), object: nil)
    }
    
    func initUI() {
        updateRoomField()
        
        nameField.text = UserDefaults.standard.string(forKey: "displayName")
        nameField.keyboardType = .default
        nameField.autocapitalizationType = .words
        nameField.textContentType = .name
        if nameField.text?.count == 0 {
            nameField.becomeFirstResponder()
        }
        
        clientHostNameField.text = "https://meet.gcorelabs.com"
        
        joinButton.layer.cornerRadius = 8
        
        videoSwitch.isOn = false
        audioSwitch.isOn = DeviceManager.isGrantedForAudio()
        
        joinOptions.isVideoOn = videoSwitch.isOn
        joinOptions.isAudioOn = audioSwitch.isOn
        joinOptions.isModerator = moderatorSwitch.isOn
        
        currentVideoView.layer.cornerRadius = 12
        currentVideoView.clipsToBounds = true
        currentVideoView.alpha = 0.0
        
        setupCaptureSession()
    }
}

// MARK: - Button Handling

private
extension JoinViewController {
    @objc func updateRoomField() {
        /**
         serv1 - не пашет с вебом "serv1abcd"
         serv0 - пашет с вебом "serv0fkfkkojt"
         */
        if let roomId = UserDefaults.standard.string(forKey: "roomId") {
            roomIdField.text = roomId
        } else {
            roomIdField.text = "serv1abcd"
        }
    }
    
    @IBAction func switchVideo(_ sender: Any) {
        switch videoSwitch.isOn {
        case true:
            DeviceManager.authorizeForVideo { [weak self] isGranted in
                DispatchQueue.main.async {
                    self?.videoSwitch.isOn = isGranted
                    self?.joinOptions.isVideoOn = isGranted
                    
                    self?.captureSession.startRunning()
                    UIView.animate(withDuration: 0.25) {
                        self?.currentVideoView.alpha = 1.0
                    }
                }
            }
        case false:
            videoSwitch.isOn = false
            joinOptions.isVideoOn = false
            
            captureSession.stopRunning()
            UIView.animate(withDuration: 0.25) {
                self.currentVideoView.alpha = 0.0
            }
        }
    }
    
    @IBAction func switchAudio(_ sender: Any) {
        switch audioSwitch.isOn {
        case true:
            DeviceManager.authorizeForAudio { [weak self] isGranted in
                DispatchQueue.main.async {
                    self?.audioSwitch.isOn = isGranted
                    self?.joinOptions.isAudioOn = isGranted
                }
            }
        case false:
            audioSwitch.isOn = false
            joinOptions.isAudioOn = false
        }
    }
    
    @IBAction func switchModerator(_ sender: Any) {
        joinOptions.isModerator = moderatorSwitch.isOn
    }
    
    @IBAction func onJoin(_ sender: Any) {
        guard let roomId = roomIdField.text,
              let name = nameField.text,
              let clientHostName = clientHostNameField.text else {
            return
        }
        
        joinOptions.roomId = roomId
        joinOptions.name = name
        joinOptions.clientHostName = clientHostName
        
        UserDefaults.standard.setValue(roomId, forKey: "roomId")
        UserDefaults.standard.setValue(name, forKey: "displayName")
        
        onJoin?(joinOptions)
        
        // Stop video session
        captureSession.stopRunning()
        UIView.animate(withDuration: 0.25) {
            self.currentVideoView.alpha = 0.0
        }
    }
    
    @IBAction func tapGesture() {
        view.endEditing(true)
    }
    
    func setupCaptureSession() {
        if let captureDevice = bestDevice(in: .front) {
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                }
            } catch let error {
                print("failed to set input error: ", error)
            }
            
            let cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            cameraLayer.frame = currentVideoView.bounds
            cameraLayer.videoGravity = .resizeAspectFill
            currentVideoView.layer.addSublayer(cameraLayer)
        }
    }
    
    func bestDevice(in position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        let devices = discoverySession.devices
        guard !devices.isEmpty else {
            return nil
        }

        return devices.first(where: { device in device.position == position })!
    }
}
