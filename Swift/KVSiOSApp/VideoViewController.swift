import UIKit
import WebRTC

class VideoViewController: UIViewController {
    @IBOutlet var localVideoView: UIView?
    private let webRTCClient: WebRTCClient
    private let signalingClient: SignalingClient
    private let localSenderClientID: String
    private let isMaster: Bool

    init(webRTCClient: WebRTCClient, signalingClient: SignalingClient, localSenderClientID: String, isMaster: Bool) {
        self.webRTCClient = webRTCClient
        self.signalingClient = signalingClient
        self.localSenderClientID = localSenderClientID
        self.isMaster = isMaster
        super.init(nibName: String(describing: VideoViewController.self), bundle: Bundle.main)

        if !isMaster {
            // In viewer mode send offer once connection is established
            webRTCClient.offer { sdp in
                self.signalingClient.sendOffer(rtcSdp: sdp, senderClientid: self.localSenderClientID)
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

        #if arch(arm64)
        // Using metal (arm64 only)
        let localRenderer = RTCMTLVideoView(frame: localVideoView?.frame ?? CGRect.zero)
        let remoteRenderer = RTCMTLVideoView(frame: view.frame)
        localRenderer.videoContentMode = .scaleAspectFill
        remoteRenderer.videoContentMode = .scaleAspectFill
        #else
        // Using OpenGLES for the rest
        let localRenderer = RTCEAGLVideoView(frame: localVideoView?.frame ?? CGRect.zero)
        let remoteRenderer = RTCEAGLVideoView(frame: view.frame)
        #endif

        webRTCClient.startCaptureLocalVideo(renderer: localRenderer)
        webRTCClient.renderRemoteVideo(to: remoteRenderer)

        if let localVideoView = self.localVideoView {
            embedView(localRenderer, into: localVideoView)
        }
        embedView(remoteRenderer, into: view)
        view.sendSubview(toBack: remoteRenderer)
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

    func sendAnswer(recipientClientID: String) {
        webRTCClient.answer { localSdp in
            self.signalingClient.sendAnswer(rtcSdp: localSdp, recipientClientId: recipientClientID)
            print("Sent answer. Update peer connection map and handle pending ice candidates")
            self.webRTCClient.updatePeerConnectionAndHandleIceCandidates(clientId: recipientClientID)
        }
    }
}
