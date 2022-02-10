
import Foundation
import GCoreVideoCallsSDK
import WebRTC
import PinLayout
import UIKit

protocol GCLRemoteViewOutput {
    var onMore: (() -> Void)? { get set }
}

class GCLRemoteView: UIView, GCLRemoteViewOutput {
    private let rtcVideoView = RTCEAGLVideoView()
    private let nameLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .white
        lbl.font = .systemFont(ofSize: 16, weight: .medium)
        return lbl
    }()
    private let avatarImageView = UIImageView()
    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "icon_more"), for: .normal)
        button.tintColor = .white
        return button
    }()
    private let videoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "video_off")
        iv.highlightedImage = UIImage(named: "video_on")
        return iv
    }()
    private let audioImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "mic_off")
        iv.highlightedImage = UIImage(named: "mic_on")
        return iv
    }()
    private let activeSpeakingView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.cornerRadius = 12
        v.layer.borderWidth = 4
        v.layer.borderColor = UIColor(rgb: 0xee5911).cgColor
        v.alpha = 0.0
        return v
    }()
    
    private var isVideoLandscape = false
    private let peerObject: PeerObject
    
    var onMore: (() -> Void)?
    
    init(peerObject: PeerObject) {
        self.peerObject = peerObject
        
        super.init(frame: .zero)
        
        initUI()
        initListeners()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        rtcVideoView.pin
            .centerLeft()
            .centerRight()
            .aspectRatio(isVideoLandscape ? 4.0 / 3.0 : 3.0 / 4.0)
        
        activeSpeakingView.pin
            .all()
        
        nameLabel.pin
            .sizeToFit()
            .bottomLeft(16)
        
        avatarImageView.pin
            .sizeToFit()
            .center()
        
        moreButton.pin
            .topLeft()
            .width(44)
            .height(44)
        
        videoImageView.pin
            .topRight(8)
            .width(28)
            .height(28)
        
        audioImageView.pin
            .centerRight(to: videoImageView.anchor.centerLeft)
            .marginRight(4)
            .width(28)
            .height(28)
    }
    
    func handleVideoTrack(_ rtcVideoTrack: RTCVideoTrack) {
        self.videoImageView.isHighlighted = true
        
        UIView.animate(withDuration: 0.25) {
            self.rtcVideoView.alpha = 1.0
            self.avatarImageView.alpha = 0.0
        }
        rtcVideoTrack.add(rtcVideoView)
    }
    
    func closeVideoTrack(_ rtcVideoTrack: RTCVideoTrack) {
        self.videoImageView.isHighlighted = false
        
        UIView.animate(withDuration: 0.25) {
            self.rtcVideoView.alpha = 0.0
            self.avatarImageView.alpha = 1.0
        } completion: { _ in
            rtcVideoTrack.remove(self.rtcVideoView)
        }
    }
    
    func isEnableAudio(_ isEnable: Bool) {
        audioImageView.isHighlighted = isEnable
    }
    
    func isSpeekingActive(_ isActive: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.activeSpeakingView.alpha = isActive ? 1.0 : 0.0
        }
    }
    
    func isShowModeratorControls(_ isShow: Bool) {
        moreButton.isHidden = !isShow
    }
}

private
extension GCLRemoteView {
    func initUI() {
        rtcVideoView.delegate = self
        rtcVideoView.alpha = 0.0
        addSubview(rtcVideoView)
        
        layer.cornerRadius = 12
        clipsToBounds = true
        backgroundColor = .black
        
        addSubview(activeSpeakingView)
        
        nameLabel.text = peerObject.displayName
        nameLabel.layer.cornerRadius = 4
        nameLabel.clipsToBounds = true
        addSubview(nameLabel)
        
        avatarImageView.image = Avatars.randomImage
        avatarImageView.tintColor = .white
        addSubview(avatarImageView)
        
        addSubview(videoImageView)
        addSubview(audioImageView)
        moreButton.isHidden = true
        addSubview(moreButton)
        
        setNeedsLayout()
    }
    
    func initListeners() {
        moreButton.addTarget(self, action: #selector(onMoreButton), for: .touchUpInside)
    }
}

private
extension GCLRemoteView {
    @objc func onMoreButton() {
        onMore?()
    }
}

extension GCLRemoteView: RTCVideoViewDelegate {
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        isVideoLandscape = size.width > size.height
        
        setNeedsLayout()
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }
}
