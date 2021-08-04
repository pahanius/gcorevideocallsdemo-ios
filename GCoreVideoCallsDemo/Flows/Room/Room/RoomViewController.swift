
import UIKit
import GCoreVideoCallsSDK
import WebRTC
import PinLayout

class RoomViewController: UIViewController, RoomViewProtocol {
    
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var localVideoView: RTCEAGLVideoView!
    @IBOutlet private weak var localNameLabel: UILabel!
    @IBOutlet private weak var mainScrollView: UIScrollView!
    @IBOutlet private weak var switchStackView: UIStackView!
    @IBOutlet private weak var audioSelectionButtonView: SelectionButtonView!
    @IBOutlet private weak var videoSelectionButtonView: SelectionButtonView!
    @IBOutlet private weak var switchCameraSelectionButtonView: SelectionButtonView!
    
    @IBOutlet private weak var localVideoAspectRationConstraint: NSLayoutConstraint!
    
    var onClose: (() -> Void)?
    
    private let roomManager = RoomManager()
    private var joinOptions: JoinOptions!
    private var remoteItems = Set<GCLRemoteItem>()
    private var peerConnectionsCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        initListeners()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateRemoteVideoTracksLayouts()
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
    }
    
    func initListeners() {
        audioSelectionButtonView.stateChanged = { [weak self] isOn in
            self?.roomManager.toggleAudio(isOn: isOn)
        }
        
        videoSelectionButtonView.stateChanged = { [weak self] isOn in
            self?.roomManager.toggleVideo(isOn: isOn)
        }
        
        switchCameraSelectionButtonView.stateChanged = { [weak self] _ in
            self?.roomManager.toggleCamera()
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
}

extension RoomViewController: RoomManagerDelegate {
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
        peers.forEach { peer in
            peerConnectionsCount += 1
            let remoteItem = GCLRemoteItem(peerObject: peer, sortId: peerConnectionsCount)
            remoteItems.insert(remoteItem)
            
            mainScrollView.addSubview(remoteItem.view)
        }
        view.setNeedsLayout()
    }
    
    func produceLocalVideoTrack(_ videoTrack: RTCVideoTrack) {
        videoTrack.add(localVideoView)
    }
    
    func produceLocalAudioTrack(_ audioTrack: RTCAudioTrack) {
        
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
        remoteItems.forEach { item in
            item.isSpeekingActive(peers.contains(item.peerId))
        }
    }
}
