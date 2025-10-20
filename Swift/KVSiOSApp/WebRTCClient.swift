import Foundation
import WebRTC

protocol WebRTCClientDelegate: class {
    func webRTCClient(_ client: WebRTCClient, didGenerate candidate: RTCIceCandidate)
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState)
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data)
}

final class WebRTCClient: NSObject {
    private static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        //support all codec formats for encode and decode
        return RTCPeerConnectionFactory(encoderFactory: RTCDefaultVideoEncoderFactory(),
                                        decoderFactory: RTCDefaultVideoDecoderFactory())
    }()

    weak var delegate: WebRTCClientDelegate?
    private let peerConnection: RTCPeerConnection
    private var videoSource: RTCVideoSource?

    // Accept video and audio from remote peer
    private let streamId = "KvsLocalMediaStream"
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                                   kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue]
    private var videoCapturer: RTCVideoCapturer?
    private var localVideoTrack: RTCVideoTrack?
    private var localAudioTrack: RTCAudioTrack?
    private var remoteVideoTrack: RTCVideoTrack?
    private var remoteDataChannel: RTCDataChannel?
    private var constructedIceServers: [RTCIceServer]?
    private var selectedResolution: VideoResolution
    private var remoteRenderer: RTCVideoRenderer?

    private var peerConnectionFoundMap = [String: RTCPeerConnection]()
    private var pendingIceCandidatesMap = [String: Set<RTCIceCandidate>]()

    required init(iceServers: [RTCIceServer], isAudioOn: Bool, isVideoOn: Bool = true, resolution: VideoResolution = .resolution720p) {
        self.selectedResolution = resolution

        let config = RTCConfiguration()
        config.iceServers = iceServers
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        config.bundlePolicy = .maxBundle
        config.keyType = .ECDSA
        config.rtcpMuxPolicy = .require
        config.tcpCandidatePolicy = .enabled

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = WebRTCClient.factory.peerConnection(with: config, constraints: constraints, delegate: nil)

        super.init()
        configureAudioSession()

        if (isAudioOn) {
        createLocalAudioStream()
        }
        if (isVideoOn) {
        createLocalVideoStream()
        }
        peerConnection.delegate = self
    }

    func configureAudioSession() {
        let audioSession = RTCAudioSession.sharedInstance()
        audioSession.isAudioEnabled = true
            do {
                try? audioSession.lockForConfiguration()
                // NOTE : Can remove .defaultToSpeaker when not required.
                try
                    audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with:.defaultToSpeaker)
                try audioSession.setMode(AVAudioSessionModeDefault)
                // NOTE : Can remove the following line when speaker not required.
                try audioSession.overrideOutputAudioPort(.speaker)
                //When passed in the options parameter of the setActive(_:options:) instance method, this option indicates that when your audio session deactivates, other audio sessions that had been interrupted by your session can return to their active state.
                try? AVAudioSession.sharedInstance().setActive(true, with: .notifyOthersOnDeactivation)
                audioSession.unlockForConfiguration()
            } catch {
              print("audioSession properties weren't set because of an error.")
              print(error.localizedDescription)
              audioSession.unlockForConfiguration()
            }
        
    }

    func shutdown() {
        peerConnection.close()

        if let stream = peerConnection.localStreams.first {
            localAudioTrack = nil
            localVideoTrack = nil
            remoteVideoTrack = nil
            peerConnection.remove(stream)
        }
        peerConnectionFoundMap.removeAll();
        pendingIceCandidatesMap.removeAll();
    }

    func offer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: mediaConstrains,
                                             optionalConstraints: nil)
        peerConnection.offer(for: constrains) { sdp, _ in
            guard let sdp = sdp else {
                return
            }

            self.peerConnection.setLocalDescription(sdp, completionHandler: { _ in
                completion(sdp)
            })
        }
    }

    func answer(completion: @escaping (_ sdp: RTCSessionDescription) -> Void) {
        let constrains = RTCMediaConstraints(mandatoryConstraints: mediaConstrains,
                                             optionalConstraints: nil)
        peerConnection.answer(for: constrains) { sdp, _ in
            guard let sdp = sdp else {
                return
            }

            self.peerConnection.setLocalDescription(sdp, completionHandler: { _ in
                completion(sdp)
            })
        }
    }

    func updatePeerConnectionAndHandleIceCandidates(clientId: String) {
        peerConnectionFoundMap[clientId] = peerConnection;
        handlePendingIceCandidates(clientId: clientId);
    }

    func handlePendingIceCandidates(clientId: String) {
        // Add any pending ICE candidates from the queue for the client ID
        if pendingIceCandidatesMap.index(forKey: clientId) != nil {
            var pendingIceCandidateListByClientId: Set<RTCIceCandidate> = pendingIceCandidatesMap[clientId]!;
            while !pendingIceCandidateListByClientId.isEmpty {
                let iceCandidate: RTCIceCandidate = pendingIceCandidateListByClientId.popFirst()!
                let peerConnectionCurrent : RTCPeerConnection = peerConnectionFoundMap[clientId]!
                peerConnectionCurrent.add(iceCandidate)
                print("Added ice candidate after SDP exchange \(iceCandidate.sdp)");
            }
            // After sending pending ICE candidates, the client ID's peer connection need not be tracked
            pendingIceCandidatesMap.removeValue(forKey: clientId)
        }
    }

    func set(remoteSdp: RTCSessionDescription, clientId: String, completion: @escaping (Error?) -> Void) {
        peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
        if remoteSdp.type == RTCSdpType.answer {
            print("Received answer for client ID: \(clientId)")
        } else {
            print("Received offer from remote")
        }
        updatePeerConnectionAndHandleIceCandidates(clientId: clientId)
    }

    func checkAndAddIceCandidate(remoteCandidate: RTCIceCandidate, clientId: String) {
        // if answer/offer is not received, it means peer connection is not found. Hold the received ICE candidates in the map.
        if peerConnectionFoundMap.index(forKey: clientId) == nil {
            print("SDP exchange not completed yet. Adding candidate: \(remoteCandidate.sdp) to pending queue")

            // If the entry for the client ID already exists (in case of subsequent ICE candidates), update the queue
            if pendingIceCandidatesMap.index(forKey: clientId) != nil {
                var pendingIceCandidateListByClientId: Set<RTCIceCandidate> = pendingIceCandidatesMap[clientId]!
                pendingIceCandidateListByClientId.insert(remoteCandidate)
                pendingIceCandidatesMap[clientId] = pendingIceCandidateListByClientId
            }
            // If the first ICE candidate before peer connection is received, add entry to map and ICE candidate to a queue
            else {
                var pendingIceCandidateListByClientId = Set<RTCIceCandidate>()
                pendingIceCandidateListByClientId.insert(remoteCandidate)
                pendingIceCandidatesMap[clientId] = pendingIceCandidateListByClientId
            }
        }
        // This is the case where peer connection is established and ICE candidates are received for the established connection
        else {
            print("Peer connection found already")
            // Remote sent us ICE candidates, add to local peer connection
            let peerConnectionCurrent : RTCPeerConnection = peerConnectionFoundMap[clientId]!
            peerConnectionCurrent.add(remoteCandidate);
            print("Added ice candidate \(remoteCandidate.sdp)");
        }
    }

    func set(remoteCandidate: RTCIceCandidate, clientId: String) {
        checkAndAddIceCandidate(remoteCandidate: remoteCandidate, clientId: clientId)
    }

    func startCaptureLocalVideo(renderer: RTCVideoRenderer) {
        guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
            return
        }

        guard let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }) else {
            print("Unable to find the front camera (selfie camera)")
            return
        }

        let targetDimensions = selectedResolution.dimensions
        let formats = RTCCameraVideoCapturer.supportedFormats(for: frontCamera)

        let selectedFormat = formats.first { format in
            let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            return dims.width == targetDimensions.width && dims.height == targetDimensions.height
        } ?? formats.first

        guard let format = selectedFormat,
              let fps = format.videoSupportedFrameRateRanges.first?.maxFrameRate else {
            debugPrint("No suitable format found")
            return
        }

        let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        print("Selected camera format: \(dims.width)x\(dims.height) at \(Int(fps.magnitude)) fps")

        capturer.startCapture(with: frontCamera,
                              format: format,
                              fps: Int(fps.magnitude))

        localVideoTrack?.add(renderer)
    }

    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        debugPrint("renderRemoteVideo called, remoteVideoTrack: \(remoteVideoTrack != nil)")
        remoteRenderer = renderer
        remoteVideoTrack?.add(renderer)
    }

    func enableVideo(_ enabled: Bool) {
        localVideoTrack?.isEnabled = enabled
    }

    func enableAudio(_ enabled: Bool) {
        localAudioTrack?.isEnabled = enabled
    }

    private func createLocalVideoStream() {
        localVideoTrack = createVideoTrack()

        if let localVideoTrack = localVideoTrack {
            peerConnection.add(localVideoTrack, streamIds: [streamId])
        }
    }

    private func createLocalAudioStream() {
        localAudioTrack = createAudioTrack()
        if let localAudioTrack  = localAudioTrack {
            peerConnection.add(localAudioTrack, streamIds: [streamId])
            let audioTracks = peerConnection.transceivers.compactMap { $0.sender.track as? RTCAudioTrack }
            audioTracks.forEach { $0.isEnabled = true }
        }
    }

    private func createVideoTrack() -> RTCVideoTrack {
        let videoSource = WebRTCClient.factory.videoSource()
        self.videoSource = videoSource
        videoCapturer = RTCCameraVideoCapturer(delegate: self)
        return WebRTCClient.factory.videoTrack(with: videoSource, trackId: "KvsVideoTrack")
    }

    private func createAudioTrack() -> RTCAudioTrack {
        let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = WebRTCClient.factory.audioSource(with: mediaConstraints)
        return WebRTCClient.factory.audioTrack(with: audioSource, trackId: "KvsAudioTrack")
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    func peerConnection(_: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        debugPrint("peerConnection stateChanged: \(stateChanged)")
    }

    func peerConnection(_: RTCPeerConnection, didAdd _: RTCMediaStream) {
        debugPrint("peerConnection did add stream")
    }

    func peerConnection(_: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        debugPrint("peerConnection didRemove stream:\(stream)")
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {
        debugPrint("peerConnection didAdd rtpReceiver: \(rtpReceiver.track?.kind ?? "unknown")")
        if rtpReceiver.track?.kind == kRTCMediaStreamTrackKindVideo {
            remoteVideoTrack = rtpReceiver.track as? RTCVideoTrack
            debugPrint("Remote video track assigned: \(remoteVideoTrack != nil)")
            // Add to renderer if we have one stored
            if let renderer = remoteRenderer {
                remoteVideoTrack?.add(renderer)
                debugPrint("Added remote video track to renderer")
            }
        }
    }

    func peerConnectionShouldNegotiate(_: RTCPeerConnection) {
        debugPrint("peerConnectionShouldNegotiate")
    }

    func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        debugPrint("peerConnection RTCIceGatheringState:\(newState)")
    }

    func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        debugPrint("peerConnection RTCIceConnectionState: \(newState)")
        delegate?.webRTCClient(self, didChangeConnectionState: newState)
    }

    func peerConnection(_: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        debugPrint("peerConnection didGenerate: \(candidate)")
        delegate?.webRTCClient(self, didGenerate: candidate)
    }

    func peerConnection(_: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        debugPrint("peerConnection didRemove \(candidates)")
    }

    func peerConnection(_: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        debugPrint("peerConnection didOpen \(dataChannel)")
        remoteDataChannel = dataChannel
    }
}

extension WebRTCClient: RTCVideoCapturerDelegate {
    func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        videoSource?.capturer(capturer, didCapture: frame)

        // If you want to rotate the frame:
        // let rotatedFrame = RTCVideoFrame(buffer: frame.buffer, rotation: ._0, timeStampNs: frame.timeStampNs)
        // videoSource?.capturer(capturer, didCapture: rotatedFrame)
    }
}

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("dataChannel didChangeState: \(dataChannel.readyState)")
    }

    func dataChannel(_: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        delegate?.webRTCClient(self, didReceiveData: buffer.data)
    }
}
