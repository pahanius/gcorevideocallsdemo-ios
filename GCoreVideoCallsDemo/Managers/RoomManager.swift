
import GCoreVideoCallsSDK
import WebRTC
import Foundation

enum StreamType: String {
    case audio
    case video
    case share
}

protocol RoomManagerDelegate {
    func startConnecting()
    func finishConnecting()
    
    func handledPeer(_ peer: PeerObject)
    func peerClosed(_ peer: String)
    func joinWithPeersInRoom(_ peers: [PeerObject])
    func joinWithPermissions(_ joinPermissions: JoinPermissionsObject)
    
    func produceLocalVideoTrack(_ videoTrack: RTCVideoTrack)
    func produceLocalAudioTrack(_ audioTrack: RTCAudioTrack)
    func didCloseLocalVideoTrack()
    
    func handledRemoteVideo(_ videoObject: VideoObject)
    func willCloseRemoteVideo(_ videoObject: VideoObject)
    func audioDidChanged(_ audioObject: AudioObject)
    func activeSpeakerPeers(_ peers: [String])
    func toggleByModerator(kind: StreamType, status: Bool)
    func acceptedPermission(kind: StreamType)
    func disableByModerator(kind: StreamType)
    func clientWaitingForModeratorJoinAccept()
    func moderatorRejectedJoinRequest()
    func moderatorIsAskedToJoin(_ moderatorIsAskedToJoin: ModeratorIsAskedToJoin)
    func requestToModerator(_ requestToModerator: RequestToModerator)
    func updateIsModerator(_ isModerator: Bool)
    func removedByModerator()
    func captureSession(_ captureSession: AVCaptureSession)
    
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
            clientHostName: joinOptions.clientHostName,
            isModerator: joinOptions.isModerator
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
    
    func askModeratorToEnableTrack(type: StreamType) {
        client?.askModeratorToEnableTrack(kind: type.rawValue)
    }
    
    func acceptedPermissionByModerator(peerId: String, type: StreamType) {
        client?.acceptedPermissionByModerator(peerId: peerId, kind: type.rawValue)
    }
    
    func rejectPermissionByModerator(peerId: String, type: StreamType) {
        client?.rejectPermissionByModerator(peerId: peerId, kind: type.rawValue)
    }
    
    func disableTrackProducerByModerator(peerId: String, type: StreamType) {
        client?.disableTrackProducerByModerator(peerId: peerId, kind: type.rawValue)
    }
    
    func acceptJoinRequestByModerator(peerId: String) {
        client?.acceptJoinRequestByModerator(peerId: peerId)
    }
    
    func rejectJoinRequestByModerator(peerId: String) {
        client?.rejectJoinRequestByModerator(peerId: peerId)
    }
    
    func removeUserByModerator(peerId: String) {
        client?.removeUserByModerator(peerId: peerId)
    }
}

// RoomListener
extension RoomManager: RoomListener {
    func roomClient(roomClient: GCoreRoomClient, captureSession: AVCaptureSession, captureDevice: AVCaptureDevice) {
        
    }
    
    func roomClientWaitingForModeratorJoinAccept() {
        delegate?.clientWaitingForModeratorJoinAccept()
    }
    
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
    }
    
    func roomClientReconnecting() {
        print("RoomListener: roomClientReconnecting")
    }
    
    func roomClientReconnectingFailed() {
        print("RoomListener: roomClientReconnectingFailed")
    }
    
    func roomClientSocketDidDisconnected(roomClient: GCoreRoomClient) {
        print("RoomListener: roomClientSocketDidDisconnected", roomClient)
    }
    
    func roomClient(roomClient: GCoreRoomClient, joinPermissions: JoinPermissionsObject) {
        print("RoomListener: joinPermissions:", joinPermissions)
        delegate?.joinWithPermissions(joinPermissions)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if self.joinOptions.isAudioOn && joinPermissions.audio {
                self.toggleAudio(isOn: self.joinOptions.isAudioOn)
                print("toggleAudio joined: ", self.joinOptions.isAudioOn)
            }
            if self.joinOptions.isVideoOn && joinPermissions.video {
                self.toggleVideo(isOn: self.joinOptions.isVideoOn)
                print("toggleVideo joined: ", self.joinOptions.isVideoOn)
            }
        }
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
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.produceLocalVideoTrack(videoTrack)
        }
    }
    
    func roomClient(roomClient: GCoreRoomClient, produceLocalAudioTrack audioTrack: RTCAudioTrack) {
        print("RoomListener: produceLocalAudioTrack:", audioTrack)
        delegate?.produceLocalAudioTrack(audioTrack)
    }
    
    func roomClient(roomClient: GCoreRoomClient, didCloseLocalVideoTrack videoTrack: RTCVideoTrack?) {
        print("RoomListener: didCloseLocalVideoTrack:", videoTrack ?? "")
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didCloseLocalVideoTrack()
        }
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
    
    func roomClient(roomClient: GCoreRoomClient, toggleByModerator kind: String, status: Bool) {
        guard let kind = StreamType(rawValue: kind) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.toggleByModerator(kind: kind, status: status)
        }
    }
    
    func roomClient(
        roomClient: GCoreRoomClient,
        acceptedPermissionFromModerator fromModerator: Bool,
        peer: PeerObject,
        requestType: String
    ) {
        guard let kind = StreamType(rawValue: requestType) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.acceptedPermission(kind: kind)
        }
    }
    
    func roomClient(
        roomClient: GCoreRoomClient,
        disableProducerByModerator kind: String
    ) {
        guard let kind = StreamType(rawValue: kind) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.disableByModerator(kind: kind)
        }
    }
    
    func roomClient(
        roomClient: GCoreRoomClient,
        moderatorIsAskedToJoin: ModeratorIsAskedToJoin
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.moderatorIsAskedToJoin(moderatorIsAskedToJoin)
        }
    }
    
    func roomClientModeratorRejectedJoinRequest() {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.moderatorRejectedJoinRequest()
        }
    }
    
    func roomClient(
        roomClient: GCoreRoomClient,
        updateMeInfo: UpdateMeInfoObject
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.updateIsModerator(updateMeInfo.role == "moderator")
        }
    }
    
    func roomClient(
        roomClient: GCoreRoomClient,
        requestToModerator: RequestToModerator
    ) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.requestToModerator(requestToModerator)
        }
    }
    
    func roomClientRemovedByModerator() {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.removedByModerator()
        }
    }
    
    func roomClient(roomClient: GCoreRoomClient, captureSession: AVCaptureSession) {
        delegate?.captureSession(captureSession)
    }
}
