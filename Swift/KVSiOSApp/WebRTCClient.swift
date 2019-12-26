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

    required init(iceServers: [RTCIceServer], isAudioOn: Bool) {
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

        if (isAudioOn) {
        createLocalAudioStream()
        }
        createLocalVideoStream()
        peerConnection.delegate = self
    }

    func shutdown() {
        peerConnection.close()

        if let stream = peerConnection.localStreams.first {
            localAudioTrack = nil
            localVideoTrack = nil
            remoteVideoTrack = nil
            peerConnection.remove(stream)
        }
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

    func set(remoteSdp: RTCSessionDescription, completion: @escaping (Error?) -> Void) {
        peerConnection.setRemoteDescription(remoteSdp, completionHandler: completion)
    }

    func set(remoteCandidate: RTCIceCandidate) {
        peerConnection.add(remoteCandidate)
    }

    func startCaptureLocalVideo(renderer: RTCVideoRenderer) {
        guard let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
            return
        }

        guard
            let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),

            let format = RTCCameraVideoCapturer.supportedFormats(for: frontCamera).last,

            let fps = format.videoSupportedFrameRateRanges.first?.maxFrameRate else {
                debugPrint("Error setting fps.")
                return
            }

        capturer.startCapture(with: frontCamera,
                              format: format,
                              fps: Int(fps.magnitude))

        localVideoTrack?.add(renderer)
    }

    func renderRemoteVideo(to renderer: RTCVideoRenderer) {
        remoteVideoTrack?.add(renderer)
    }

    private func createLocalVideoStream() {
        localVideoTrack = createVideoTrack()

        if let localVideoTrack = localVideoTrack {
            peerConnection.add(localVideoTrack, streamIds: [streamId])
            remoteVideoTrack = peerConnection.transceivers.first { $0.mediaType == .video }?.receiver.track as? RTCVideoTrack
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
        videoSource.adaptOutputFormat(toWidth: 1280, height: 720, fps: 30)
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
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

extension WebRTCClient: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("dataChannel didChangeState: \(dataChannel.readyState)")
    }

    func dataChannel(_: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        delegate?.webRTCClient(self, didReceiveData: buffer.data)
    }
}
