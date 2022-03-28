
import UIKit
import GCoreVideoCallsSDK
import WebRTC
import PinLayout
import AVFoundation

class RoomViewController: UIViewController, RoomViewProtocol {
    
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var roomName: UILabel!
    @IBOutlet private weak var localVideoView: RTCEAGLVideoView!
    @IBOutlet private weak var localNameLabel: UILabel!
    @IBOutlet private weak var mainScrollView: UIScrollView!
    @IBOutlet private weak var switchStackView: UIStackView!
    @IBOutlet private weak var audioSelectionButtonView: SelectionButtonView!
    @IBOutlet private weak var videoSelectionButtonView: SelectionButtonView!
    @IBOutlet private weak var switchCameraSelectionButtonView: SelectionButtonView!
    @IBOutlet private weak var loggerView: LoggerView!
    @IBOutlet private weak var showLogButton: UIButton!
    @IBOutlet private weak var loaderView: UIView!
    @IBOutlet private weak var loaderBackView: UIView!
    @IBOutlet private weak var centerInfoLabel: UILabel!
    @IBOutlet private weak var moderatorLabel: UILabel!
    
    @IBOutlet private weak var localVideoAspectRationConstraint: NSLayoutConstraint!
    
    var onClose: (() -> Void)?
    
    private let roomManager = RoomManager()
    private var joinOptions: JoinOptions!
    private var remoteItems = Set<GCLRemoteItem>()
    private var isModerator: Bool = false
    private var peerConnectionsCount = 0
    private var onAnimating: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.15) {
                self.loaderView.alpha = self.onAnimating ? 1.0 : 0.0
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        initListeners()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateRemoteVideoTracksLayouts()
        setRemoteItemsListeners()
        updateModeratorStatus()
    }
    
    func configure(joinOptions: JoinOptions) {
        self.joinOptions = joinOptions
    }
    
    func initUI() {
        closeButton.layer.cornerRadius = closeButton.bounds.width / 2.0
        
        audioSelectionButtonView.setType(.microphone)
        audioSelectionButtonView.isOn = joinOptions.isAudioOn
        
        videoSelectionButtonView.setType(.camera)
        videoSelectionButtonView.isOn = joinOptions.isVideoOn
        
        switchCameraSelectionButtonView.setType(.switchCamera)
                
        roomManager.openConnection(joinOptions: joinOptions, delegate: self)
        
        localVideoView.layer.cornerRadius = 12
        localVideoView.clipsToBounds = true
        localVideoView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        localVideoView.delegate = self
        
        localNameLabel.text = joinOptions.name
        localNameLabel.textColor = .white
        
        roomName.text = joinOptions.roomId
        
        loggerView.alpha = 0.0
        loaderView.alpha = 0.0
        loaderBackView.layer.cornerRadius = 16
        
        centerInfoLabel.text = "Please wait, the meeting host will let you in soon"
        centerInfoLabel.isHidden = true
        
        moderatorLabel.isHidden = true
    }
    
    func initListeners() {
        audioSelectionButtonView.stateChanged = { [weak self] isOn in
            if self?.audioSelectionButtonView.isEnabled == true {
                self?.roomManager.toggleAudio(isOn: isOn)
            } else {
                let alert = UIAlertController(
                    title: "Mics are currently disabled in this room",
                    message: "Ask moderator to enable mic?",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                    self?.roomManager.askModeratorToEnableTrack(type: .audio)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
                self?.present(alert, animated: true, completion: nil)
            }
        }
        
        videoSelectionButtonView.stateChanged = { [weak self] isOn in
            if self?.videoSelectionButtonView.isEnabled == true {
                self?.roomManager.toggleVideo(isOn: isOn)
            } else {
                let alert = UIAlertController(
                    title: "Webcams are currently disabled in this room",
                    message: "Ask moderator to enable webcam?",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                    self?.roomManager.askModeratorToEnableTrack(type: .video)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
                self?.present(alert, animated: true, completion: nil)
            }
        }
        
        switchCameraSelectionButtonView.stateChanged = { [weak self] _ in
            self?.roomManager.toggleCamera()
        }
    }
    
    func setRemoteItemsListeners() {
        remoteItems.forEach { item in
            item.view.onMore = {
                let message: String
                if let displayName = item.displayName {
                    message = "Make your judgment for \(displayName)"
                } else {
                    message = "Make your judgment"
                }
                let alert = UIAlertController(
                    title: "Feel the power",
                    message: message,
                    preferredStyle: .actionSheet
                )
                alert.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { action in
                    self.roomManager.removeUserByModerator(peerId: item.peerId)
                }))
                alert.addAction(UIAlertAction(title: "Mute mic", style: .default, handler: { action in
                    self.roomManager.disableTrackProducerByModerator(peerId: item.peerId, type: .audio)
                }))
                alert.addAction(UIAlertAction(title: "Turn off webcam", style: .default, handler: { action in
                    self.roomManager.disableTrackProducerByModerator(peerId: item.peerId, type: .video)
                }))
                alert.addAction(UIAlertAction(title: "Turn off sharing", style: .default, handler: { action in
                    self.roomManager.disableTrackProducerByModerator(peerId: item.peerId, type: .share)
                }))
                alert.addAction(UIAlertAction(title: "Enable mic", style: .default, handler: { action in
                    self.roomManager.acceptedPermissionByModerator(peerId: item.peerId, type: .audio)
                }))
                alert.addAction(UIAlertAction(title: "Enable webcam", style: .default, handler: { action in
                    self.roomManager.acceptedPermissionByModerator(peerId: item.peerId, type: .video)
                }))
                alert.addAction(UIAlertAction(title: "Enable sharing", style: .default, handler: { action in
                    self.roomManager.acceptedPermissionByModerator(peerId: item.peerId, type: .share)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

extension RoomViewController: RTCVideoViewDelegate {
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        print("didChangeVideoSize", size)
        

//        if videoView.isEqual(localVideoView)  {
//            localVideoView.removeConstraint(localVideoAspectRationConstraint)
//            localVideoAspectRationConstraint = localVideoView.heightAnchor.constraint(equalTo: localVideoView.widthAnchor, multiplier: size.height / size.width)
//            localVideoAspectRationConstraint.isActive = true
//        }
    }
}

// MARK: - Button Handling

private
extension RoomViewController {
    @IBAction func onShowLog(_ sender: Any) {
        showLogButton.setTitle(
            "\(self.loggerView.alpha == 0.0 ? "Hide" : "Show") Log",
            for: .normal
        )
        
        UIView.animate(withDuration: 0.15) {
            self.loggerView.alpha = self.loggerView.alpha == 0.0 ? 1.0 : 0.0
        }
    }
    
    @IBAction func onClose(_ sender: Any) {
        onClose?()
        roomManager.closeConnection()
    }
    
    func updateRemoteVideoTracksLayouts() {
        let remotesArray = remoteItems
            .sorted(by: { $0.sortId < $1.sortId })
            .map({ $0.view })
        if remotesArray.count == 1 {
            remotesArray[0].pin
                .top()
                .left(16)
                .right(16)
                .width(UIScreen.main.bounds.width - 32)
                .aspectRatio(3.0 / 4.0)
        } else {
            for (index, view) in remotesArray.enumerated() {
                if index % 2 == 0 {
                    if index == 0 {
                        view.pin
                            .top()
                            .left(16)
                            .width(UIScreen.main.bounds.width / 2 - 24)
                            .aspectRatio(3.0 / 4.0)
                    } else {
                        view.pin
                            .topLeft(to: remotesArray[index - 2].anchor.bottomLeft)
                            .topRight(to: remotesArray[index - 2].anchor.bottomRight)
                            .aspectRatio(3.0 / 4.0)
                            .marginVertical(16)
                    }
                } else {
                    if index == 1 {
                        view.pin
                            .topLeft(to: remotesArray[index - 1].anchor.topRight)
                            .bottomLeft(to: remotesArray[index - 1].anchor.bottomRight)
                            .marginHorizontal(16)
                            .right()
                    } else {
                        view.pin
                            .topRight(to: remotesArray[index - 2].anchor.bottomRight)
                            .bottomLeft(to: remotesArray[index - 1].anchor.bottomRight)
                            .margin(PEdgeInsets(top: 16, left: 16, bottom: 0, right: 0))
                    }
                }
            }
        }

        mainScrollView.contentSize = CGSize(
            width: UIScreen.main.bounds.width,
            height: (remotesArray.last?.frame.maxY ?? 0) + 16
        )
        mainScrollView.contentInset = UIEdgeInsets(
            top: localVideoView.frame.maxY + 16,
            left: 0,
            bottom: view.safeAreaInsets.bottom + switchStackView.frame.height + 16,
            right: 0
        )
    }
    
    func isWaitingForJoin(_ isWaiting: Bool) {
        if isWaiting {
            onAnimating = true
            centerInfoLabel.isHidden = false
        } else {
            onAnimating = false
            centerInfoLabel.isHidden = true
        }
    }
    
    func updateModeratorStatus() {
        moderatorLabel.isHidden = !isModerator
        remoteItems.forEach { item in
            item.isShowModeratorControls(isModerator)
        }
    }
}

private
extension RoomViewController {
    func localVideoView(isEnabled: Bool) {
        localVideoView.layer.borderColor = UIColor.red.cgColor
        localVideoView.layer.borderWidth = isEnabled ? 0.0 : 1.0
    }
}

extension RoomViewController: RoomManagerDelegate {
    func clientWaitingForModeratorJoinAccept() {
        isWaitingForJoin(true)
    }
    
    func startConnecting() {
        onAnimating = true
    }
    
    func finishConnecting() {
        onAnimating = false
    }
    
    func handledPeer(_ peer: PeerObject) {
        peerConnectionsCount += 1
        let remoteItem = GCLRemoteItem(peerObject: peer, sortId: peerConnectionsCount)
        remoteItems.insert(remoteItem)
        
        mainScrollView.addSubview(remoteItem.view)
        view.setNeedsLayout()
    }
    
    func peerClosed(_ peer: String) {
        if let remoteItem = remoteItems.first(where: { $0.peerId == peer }) {
            remoteItem.view.removeFromSuperview()
            remoteItems.remove(remoteItem)
        }
        view.setNeedsLayout()
    }
    
    func joinWithPeersInRoom(_ peers: [PeerObject]) {
        remoteItems.removeAll()
        
        peers.forEach { peer in
            peerConnectionsCount += 1
            let remoteItem = GCLRemoteItem(peerObject: peer, sortId: peerConnectionsCount)
            remoteItems.insert(remoteItem)
            
            mainScrollView.addSubview(remoteItem.view)
        }
        view.setNeedsLayout()
    }
    
    func joinWithPermissions(_ joinPermissions: JoinPermissionsObject) {
        isWaitingForJoin(false)
        
        audioSelectionButtonView.isEnabled = joinPermissions.audio
        videoSelectionButtonView.isEnabled = joinPermissions.video
    }
    
    func produceLocalVideoTrack(_ videoTrack: RTCVideoTrack) {
        videoTrack.add(localVideoView)
        localVideoView(isEnabled: true)
    }
    
    func produceLocalAudioTrack(_ audioTrack: RTCAudioTrack) {
        
    }
    
    func didCloseLocalVideoTrack() {
        localVideoView(isEnabled: false)
    }
    
    func handledRemoteVideo(_ videoObject: VideoObject) {
        if let remoteItem = remoteItems.first(where: { $0.peerId == videoObject.peerId }) {
            remoteItem.handleVideoTrack(videoObject.rtcVideoTrack)
        }
    }
    
    func willCloseRemoteVideo(_ videoObject: VideoObject) {
        if let remoteItem = remoteItems.first(where: { $0.peerId == videoObject.peerId }) {
            remoteItem.closeVideoTrack(videoObject.rtcVideoTrack)
        }
    }
    
    func audioDidChanged(_ audioObject: AudioObject) {
        if let remoteItem = remoteItems.first(where: { $0.peerId == audioObject.peerId }) {
            remoteItem.isEnableAudio(audioObject.rtcAudioTrack.isEnabled)
        }
    }
    
    func activeSpeakerPeers(_ peers: [String]) {
        print(peers)
        remoteItems.forEach { item in
            item.isSpeekingActive(peers.contains(item.peerId))
        }
    }
    
    func toggleByModerator(kind: StreamType, status: Bool) {
        switch kind {
        case .audio:
            audioSelectionButtonView.isEnabled = status
        case .video:
            videoSelectionButtonView.isEnabled = status
        case .share:
            break
        }
    }
    
    func acceptedPermission(kind: StreamType) {
        switch kind {
        case .audio:
            audioSelectionButtonView.isEnabled = true
            let alert = UIAlertController(
                title: "Request from moderator",
                message: "Enable mic?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.audioSelectionButtonView.isOn = true
                self.roomManager.toggleAudio(isOn: true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
            self.present(alert, animated: true, completion: nil)
        case .video:
            videoSelectionButtonView.isEnabled = true
            videoSelectionButtonView.isEnabled = true
            let alert = UIAlertController(
                title: "Request from moderator",
                message: "Enable video?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                self.videoSelectionButtonView.isOn = true
                self.roomManager.toggleVideo(isOn: true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in }))
            self.present(alert, animated: true, completion: nil)
        case .share:
            break
        }
    }
    
    func disableByModerator(kind: StreamType) {
        switch kind {
        case .audio:
            audioSelectionButtonView.isEnabled = false
        case .video:
            videoSelectionButtonView.isEnabled = false
        case .share:
            break
        }
    }
    
    func logger(_ message: String) {
        DispatchQueue.main.async {
            self.loggerView.append(message)
        }
    }
    
    func moderatorIsAskedToJoin(_ moderatorIsAskedToJoin: ModeratorIsAskedToJoin) {
        let alert = UIAlertController(
            title: "Hey!",
            message: "\(moderatorIsAskedToJoin.userName) wants to come in",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Admin", style: .default, handler: { action in
            self.roomManager.acceptJoinRequestByModerator(peerId: moderatorIsAskedToJoin.peerId)
        }))
        alert.addAction(UIAlertAction(title: "Reject", style: .cancel, handler: { action in
            self.roomManager.rejectJoinRequestByModerator(peerId: moderatorIsAskedToJoin.peerId)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func requestToModerator(_ requestToModerator: RequestToModerator) {
        let alert = UIAlertController(
            title: "Hey!",
            message: "\(requestToModerator.userName) wants to enable \(requestToModerator.requestType)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Admin", style: .default, handler: { action in
            self.roomManager.acceptedPermissionByModerator(
                peerId: requestToModerator.peerId,
                type: StreamType(rawValue: requestToModerator.requestType)!
            )
        }))
        alert.addAction(UIAlertAction(title: "Reject", style: .cancel, handler: { action in
            self.roomManager.rejectPermissionByModerator(
                peerId: requestToModerator.peerId,
                type: StreamType(rawValue: requestToModerator.requestType)!
            )
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func moderatorRejectedJoinRequest() {
        onClose?()
    }
    
    func updateIsModerator(_ isModerator: Bool) {
        self.isModerator = isModerator
        updateModeratorStatus()
    }
    
    func removedByModerator() {
        onClose?()
    }
    
    func captureSession(_ captureSession: AVCaptureSession) {
//        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        previewLayer.videoGravity = .resizeAspectFill
//        previewLayer.frame = CGRect(x: 0, y: 300, width: 320, height: 500)
//
//        self.view.layer.addSublayer(previewLayer)
    }
}
