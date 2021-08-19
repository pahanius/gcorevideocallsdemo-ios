
import GCoreVideoCallsSDK
import WebRTC

protocol RoomManagerDelegate {
    func startConnecting()
    func finishConnecting()
    
    func handledPeer(_ peer: PeerObject)
    func peerClosed(_ peer: String)
    func joinWithPeersInRoom(_ peers: [PeerObject])
    
    func produceLocalVideoTrack(_ videoTrack: RTCVideoTrack)
    func produceLocalAudioTrack(_ audioTrack: RTCAudioTrack)
    
    func handledRemoteVideo(_ videoObject: VideoObject)
    func willCloseRemoteVideo(_ videoObject: VideoObject)
    func audioDidChanged(_ audioObject: AudioObject)
    func activeSpeakerPeers(_ peers: [String])
    
    func logger(_ message: String)
}

final class RoomManager {
    private var client: GCoreRoomClient?
    private var joinOptions: JoinOptions!
    
    var delegate: RoomManagerDelegate?
    
    func openConnection(joinOptions: JoinOptions, delegate: RoomManagerDelegate) {
        self.delegate = delegate
        self.joinOptions = joinOptions
        
        GCoreRoomLogger.activateLogger()
        GCoreRoomLogger.log = { [weak self] message in
            self?.delegate?.logger(message)
        }
        
        let options = RoomOptions(cameraPosition: .front)
        let parameters = MeetRoomParametrs(
            roomId: joinOptions.roomId,
            displayName: joinOptions.name,
            clientHostName: joinOptions.clientHostName
        )
        
        client = GCoreRoomClient(roomOptions: options, requestParameters: parameters, roomListener: self)
        try? client?.open()
        client?.audioSessionActivate()
    }
    
    func closeConnection() {
        client?.close()
    }
    
    func toggleVideo(isOn: Bool) {
        client?.toggleVideo(isOn: isOn)
        debugPrint("toggleVideo: ", isOn)
    }
    
    func toggleAudio(isOn: Bool) {
        client?.toggleAudio(isOn: isOn)
        debugPrint("toggleAudio: ", isOn)
    }
    
    func toggleCamera() {
        client?.toggleCameraPosition(completion: { error in
            if let error = error {
                debugPrint(error)
            }
        })
    }
}

// RoomListener
extension RoomManager: RoomListener {
    func roomClientStartToConnectWithServices() {
        delegate?.startConnecting()
    }
    
    func roomClientSuccessfullyConnectWithServices() {
        delegate?.finishConnecting()
    }
    
    func roomClientHandle(error: RoomError) {
        debugPrint("RoomListener:", error.localizedDescription)
    }
    
    func roomClientDidConnected() {
        debugPrint("RoomListener: roomClientDidConnected")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.joinOptions.isVideoOn {
                self.toggleVideo(isOn: self.joinOptions.isVideoOn)
                print("toggleVideo joined: ", self.joinOptions.isVideoOn)
            }
            
            if self.joinOptions.isAudioOn {
                self.toggleAudio(isOn: self.joinOptions.isAudioOn)
                print("toggleAudio joined: ", self.joinOptions.isAudioOn)
            }
        }
    }
    
    func roomClientReconnecting() {
        print("RoomListener: roomClientReconnecting")
    }
    
    func roomClientReconnectingFailed() {
        print("RoomListener: roomClientReconnectingFailed")
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            try? self.client?.open()
//        }
    }
    
    func roomClientSocketDidDisconnected(roomClient: GCoreRoomClient) {
        print("RoomListener: roomClientSocketDidDisconnected", roomClient)
    }
    
    func roomClient(roomClient: GCoreRoomClient, joinWithPeersInRoom peers: [PeerObject]) {
        print("RoomListener: joinWithPeersInRoom peers:", peers)
        delegate?.joinWithPeersInRoom(peers)
    }
    
    func roomClient(roomClient: GCoreRoomClient, handlePeer: PeerObject) {
        delegate?.handledPeer(handlePeer)
        print("RoomListener: handlePeer:", handlePeer.displayName ?? "name unknown")
    }
    
    func roomClient(roomClient: GCoreRoomClient, peerClosed: String) {
        delegate?.peerClosed(peerClosed)
        print("RoomListener: peerClosed:", peerClosed)
    }
    
    func roomClient(roomClient: GCoreRoomClient, produceLocalVideoTrack videoTrack: RTCVideoTrack) {
        print("RoomListener: produceLocalVideoTrack:", videoTrack)
        delegate?.produceLocalVideoTrack(videoTrack)
    }
    
    func roomClient(roomClient: GCoreRoomClient, produceLocalAudioTrack audioTrack: RTCAudioTrack) {
        print("RoomListener: produceLocalAudioTrack:", audioTrack)
        delegate?.produceLocalAudioTrack(audioTrack)
    }
    
    func roomClient(roomClient: GCoreRoomClient, didCloseLocalVideoTrack videoTrack: RTCVideoTrack?) {
        print("RoomListener: didCloseLocalVideoTrack:", videoTrack ?? "")
    }
    
    func roomClient(roomClient: GCoreRoomClient, didCloseLocalAudioTrack audioTrack: RTCAudioTrack?) {
        print("RoomListener: didCloseLocalAudioTrack:", audioTrack ?? "")
    }
    
    // MARK: - Remote
    
    // Video
    func roomClient(roomClient: GCoreRoomClient, handledRemoteVideo videoObject: VideoObject) {
        print("RoomListener: handledRemoteVideoTrack:", videoObject)
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.handledRemoteVideo(videoObject)
        }
    }
    
    func roomClient(roomClient: GCoreRoomClient, didCloseRemoteVideoByModerator byModerator: Bool, videoObject: VideoObject) {
        print("RoomListener: didCloseRemoteVideoByModerator:", videoObject)
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.willCloseRemoteVideo(videoObject)
        }
    }
    
    // Audio
    func roomClient(roomClient: GCoreRoomClient, produceRemoteAudio audioObject: AudioObject) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.audioDidChanged(audioObject)
        }
    }

    func roomClient(roomClient: GCoreRoomClient, didCloseRemoteAudioByModerator byModerator: Bool, audioObject: AudioObject) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.audioDidChanged(audioObject)
        }
    }
    
    func roomClient(roomClient: GCoreRoomClient, activeSpeakerPeers peers: [String]) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.activeSpeakerPeers(peers)
        }
    }
}
