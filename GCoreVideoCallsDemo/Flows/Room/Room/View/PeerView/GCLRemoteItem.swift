
import Foundation
import GCoreVideoCallsSDK
import WebRTC
import PinLayout

class GCLRemoteItem: Hashable {
    let view: GCLRemoteView
    
    private let peerObject: PeerObject
    let sortId: Int
    
    var trackId: String?
    var peerId: String {
        peerObject.id
    }
    
    init(peerObject: PeerObject, sortId: Int) {
        self.peerObject = peerObject
        self.sortId = sortId
        self.view = GCLRemoteView(peerObject: peerObject)
    }
    
    func handleVideoTrack(_ rtcVideoTrack: RTCVideoTrack) {
        /**
         Если для этого пира уже используется видеопоток, новый не добавляем
         */
        if trackId == nil {
            trackId = rtcVideoTrack.trackId
            view.handleVideoTrack(rtcVideoTrack)
        }
    }
    
    func closeVideoTrack(_ rtcVideoTrack: RTCVideoTrack) {
        trackId = nil
        view.closeVideoTrack(rtcVideoTrack)
    }
    
    func isEnableAudio(_ isEnable: Bool) {
        view.isEnableAudio(isEnable)
    }
    
    func isSpeekingActive(_ isActive: Bool) {
        view.isSpeekingActive(isActive)
    }
}

extension GCLRemoteItem {
    static func == (lhs: GCLRemoteItem, rhs: GCLRemoteItem) -> Bool {
        lhs.peerObject.id == rhs.peerObject.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(peerObject.id)
    }
}
