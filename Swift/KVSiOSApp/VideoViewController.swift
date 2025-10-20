import UIKit
import AWSKinesisVideo
import AWSKinesisVideoWebRTCStorage
import WebRTC

class VideoViewController: UIViewController {
    @IBOutlet var localVideoView: UIView?
    
    private let webRTCClient: WebRTCClient
    private let signalingClient: SignalingClient
    private let localSenderClientID: String
    private let isMaster: Bool
    private let signalingChannelArn: String?
    private let isVideoEnabled: Bool
    private var hasReceivedOffer = false
    private var storageSessionConnectionAttempts: [Date]

    init(webRTCClient: WebRTCClient, signalingClient: SignalingClient, localSenderClientID: String, isMaster: Bool, signalingChannelArn: String?, isVideoEnabled: Bool = true) {
        self.webRTCClient = webRTCClient
        self.signalingClient = signalingClient
        self.localSenderClientID = localSenderClientID
        self.isMaster = isMaster
        self.signalingChannelArn = signalingChannelArn
        self.isVideoEnabled = isVideoEnabled
        self.storageSessionConnectionAttempts = []
        super.init(nibName: String(describing: VideoViewController.self), bundle: Bundle.main)
        
        let isStorageSession: Bool = self.signalingChannelArn != nil
        print("isStorageSession? \(isStorageSession)")
        print("role: \(isMaster ? "master" : "viewer")")
        
        if !isStorageSession && !isMaster {
            // In viewer mode send offer once connection is established
            webRTCClient.offer { sdp in
                self.signalingClient.sendOffer(rtcSdp: sdp, senderClientid: self.localSenderClientID)
            }
        }

        if isStorageSession {
            DispatchQueue.global(qos: .background).async {
                self.joinStorageSessionWithRetry()
            }
        }
    }
    
    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let isIngestMode = signalingChannelArn != nil
        
        #if arch(arm64)
        let localRenderer = RTCMTLVideoView(frame: localVideoView?.frame ?? CGRect.zero)
        let remoteRenderer = RTCMTLVideoView(frame: view.frame)
        localRenderer.videoContentMode = .scaleAspectFill
        remoteRenderer.videoContentMode = .scaleAspectFill
        #else
        let localRenderer = RTCEAGLVideoView(frame: localVideoView?.frame ?? CGRect.zero)
        let remoteRenderer = RTCEAGLVideoView(frame: view.frame)
        #endif

        if isIngestMode && isMaster {
            // Ingestion master: local view only
            webRTCClient.startCaptureLocalVideo(renderer: localRenderer)
            embedView(localRenderer, into: view)
            view.sendSubview(toBack: localRenderer)
            localVideoView?.isHidden = true
        } else if isIngestMode && !isMaster {
            // Ingestion viewer: remote view only
            webRTCClient.renderRemoteVideo(to: remoteRenderer)
            embedView(remoteRenderer, into: view)
            view.sendSubview(toBack: remoteRenderer)
            localVideoView?.isHidden = true
        } else {
            // Non-ingestion: remote fullscreen + local in corner
            if isVideoEnabled {
                webRTCClient.startCaptureLocalVideo(renderer: localRenderer)
                if let localVideoView = self.localVideoView {
                    embedView(localRenderer, into: localVideoView)
                }
            } else {
                localVideoView?.isHidden = true
            }
            webRTCClient.renderRemoteVideo(to: remoteRenderer)
            embedView(remoteRenderer, into: view)
            view.sendSubview(toBack: remoteRenderer)
        }
    }

    private func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view": view]))

        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view": view]))
        containerView.layoutIfNeeded()
    }

    @IBAction func backDidTap(_: Any) {
        webRTCClient.shutdown()
        signalingClient.disconnect()
        dismiss(animated: true)
    }
    
    func joinStorageSessionWithRetry() {
        guard let signalingChannelArn = self.signalingChannelArn else {
            print("joinStorageSessionWithRetry IllegalState! ARN cannot be nil")
            return
        }
        
        // If we already received an offer, stop retrying
        if hasReceivedOffer {
            print("SDP offer received, stopping storage session retries")
            return
        }
        
        // Clean up attempts older than 10 minutes
        let tenMinutesAgo = Date().addingTimeInterval(-600)
        storageSessionConnectionAttempts = storageSessionConnectionAttempts.filter { $0 > tenMinutesAgo }
        
        // Check if we've exceeded 3 attempts in the last 10 minutes
        if storageSessionConnectionAttempts.count >= 3 {
            print("Too many storage session attempts (3) within 10 minutes. Stopping retries.")
            return
        }
        
        // Record this attempt
        storageSessionConnectionAttempts.append(Date())
        
        let webrtcStorageClient = AWSKinesisVideoWebRTCStorage(forKey: awsKinesisVideoKey)

        if self.isMaster {
            let joinStorageSessionRequest = AWSKinesisVideoWebRTCStorageJoinStorageSessionInput()
            joinStorageSessionRequest?.channelArn = signalingChannelArn
            
            print("Calling JoinStorageSession with ARN: \(signalingChannelArn) (attempt \(storageSessionConnectionAttempts.count))")

            webrtcStorageClient.joinSession(joinStorageSessionRequest!).continueWith(block: { (task) -> Void in
                if let error = task.error {
                    print("Error joining storage session: \(error)")
                } else {
                    print("Joined storage session!")
                }

                // Retry after 6 seconds if no offer received yet
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 6.0) {
                    self.joinStorageSessionWithRetry()
                }
            })
        } else {
            let joinStorageSessionAsViewerRequest = AWSKinesisVideoWebRTCStorageJoinStorageSessionAsViewerInput()
            joinStorageSessionAsViewerRequest?.channelArn = signalingChannelArn
            joinStorageSessionAsViewerRequest?.clientId = self.localSenderClientID

            print("Calling JoinStorageSessionAsViewer with ARN: \(signalingChannelArn) and clientId: \(self.localSenderClientID) (attempt \(storageSessionConnectionAttempts.count))")
            
            webrtcStorageClient.joinSession(asViewer: joinStorageSessionAsViewerRequest!).continueWith(block: { (task) -> Void in
                if let error = task.error {
                    print("Error joining storage session: \(error)")
                } else {
                    print("Joined storage session!")
                }

                // Retry after 6 seconds if no offer received yet
                DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 6.0) {
                    self.joinStorageSessionWithRetry()
                }
            })
        }
    }
    
    func markOfferReceived() {
        hasReceivedOffer = true
    }

    func sendAnswer(recipientClientID: String) {
        webRTCClient.answer { localSdp in
            self.signalingClient.sendAnswer(rtcSdp: localSdp, recipientClientId: recipientClientID)
            print("Sent answer. Update peer connection map and handle pending ice candidates")
            self.webRTCClient.updatePeerConnectionAndHandleIceCandidates(clientId: recipientClientID)
        }
    }
    
    func showToast(message: String, length: String = "short") {
        guard length == "short" || length == "long" else {
            print("showToast: Invalid argument - length must either be short or long")
            return
        }
        
        let durationSec = length == "short" ? 2.0 : 3.5
        let padding: CGFloat = 12
        
        let toastContainer = UIView()
        toastContainer.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastContainer.layer.cornerRadius = 10
        toastContainer.translatesAutoresizingMaskIntoConstraints = false
        toastContainer.alpha = 0.0
        
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textAlignment = .center
        toastLabel.textColor = UIColor.white
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.numberOfLines = 0
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        toastContainer.addSubview(toastLabel)
        self.view.addSubview(toastContainer)
        
        NSLayoutConstraint.activate([
            toastLabel.topAnchor.constraint(equalTo: toastContainer.topAnchor, constant: padding),
            toastLabel.bottomAnchor.constraint(equalTo: toastContainer.bottomAnchor, constant: -padding),
            toastLabel.leadingAnchor.constraint(equalTo: toastContainer.leadingAnchor, constant: padding),
            toastLabel.trailingAnchor.constraint(equalTo: toastContainer.trailingAnchor, constant: -padding),
            toastContainer.leadingAnchor.constraint(greaterThanOrEqualTo: self.view.leadingAnchor, constant: 20),
            toastContainer.trailingAnchor.constraint(lessThanOrEqualTo: self.view.trailingAnchor, constant: -20),
            toastContainer.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            toastContainer.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])

        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
            toastContainer.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: durationSec, options: .curveEaseIn, animations: {
                toastContainer.alpha = 0.0
            }) { _ in
                toastContainer.removeFromSuperview()
            }
        }
    }
}
