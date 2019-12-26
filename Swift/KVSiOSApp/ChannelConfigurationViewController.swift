import AWSCore
import AWSCognitoIdentityProvider
import AWSKinesisVideo
import AWSKinesisVideoSignaling
import AWSMobileClient
import Foundation
import WebRTC

class ChannelConfigurationViewController: UIViewController, UITextFieldDelegate {

    var userListDevicesResponse: AWSCognitoIdentityUserListDevicesResponse?
    var user: AWSCognitoIdentityUser?
    var pool: AWSCognitoIdentityUserPool?
    var userDetailsResponse: AWSCognitoIdentityUserGetDetailsResponse?
    var userSessionResponse: AWSCognitoIdentityUserSession?
    var AWSCredentials: AWSCredentials?
    var wssURL: URL?
    var signalingClient: SignalingClient?
    var channelARN: String?
    var isMaster: Bool?
    var webRTCClient: WebRTCClient?
    var iceServerList: [AWSKinesisVideoSignalingIceServer]?
    var vc: VideoViewController?
    var awsRegionType: AWSRegionType = .Unknown
    var signalingConnected: Bool = false
    var sendAudioEnabled: Bool = true
    var remoteSenderClientId: String?
    lazy var localSenderId: String = {
        return connectAsViewClientId
    }()

    @IBOutlet var connectedLabel: UILabel!
    @IBOutlet var channelName: UITextField!
    @IBOutlet var clientID: UITextField!
    @IBOutlet var regionName: UITextField!
    @IBOutlet var isAudioEnabled: UISwitch!

    @IBOutlet weak var connectAsMasterButton: UIButton!
    @IBOutlet weak var connectAsViewerButton: UIButton!
    
    var peerConnection: RTCPeerConnection?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.signalingConnected = false
        updateConnectionLabel()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.signalingConnected = false
        updateConnectionLabel()

        channelName.delegate = self
        clientID.delegate = self
        regionName.delegate = self
    }

    func textFieldShouldReturn(_: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(false, animated: true)
    }

    @IBAction func audioStateChanged(sender: UISwitch!) {
        if sender.isOn {
            self.sendAudioEnabled = true
        } else {
            self.sendAudioEnabled = false
        }
    }

    @IBAction func connectAsViewer(_sender _: AnyObject) {
        isMaster = false
        connectAsRole(role: viewerRole, connectAsUser: (connectAsViewerKey))
    }

    @IBAction func connectAsMaster(_: AnyObject) {
        isMaster = true
        connectAsRole(role: masterRole, connectAsUser: (connectAsMasterKey))
    }

    @IBAction func signOut(_ sender: AnyObject) {
        AWSMobileClient.default().signOut()
        let mainStoryBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        self.present((mainStoryBoard.instantiateViewController(withIdentifier: "signinController") as? UINavigationController)!, animated: true, completion: nil)
    }

    func connectAsRole(role: String, connectAsUser: String) {
        guard let channelNameValue = self.channelName.text?.trim(), !channelNameValue.isEmpty else {
            let alertController = UIAlertController(title: "Missing Required Fields",
                                                    message: "Channel name is required for WebRTC connection",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)

            present(alertController, animated: true, completion: nil)
            return
        }
        guard let awsRegionValue = self.regionName.text?.trim(), !awsRegionValue.isEmpty else {
            let alertController = UIAlertController(title: "Missing Required Fields",
                                                    message: "Region name is required for WebRTC connection",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            return
        }

        self.awsRegionType = awsRegionValue.aws_regionTypeValue()
        if (self.awsRegionType == .Unknown) {
            let alertController = UIAlertController(title: "Invalid Region Field",
                                                    message: "Enter a valid AWS region name",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)

            self.present(alertController, animated: true, completion: nil)
            return
        }
        if (self.clientID.text!.isEmpty) {
            self.localSenderId = NSUUID().uuidString.lowercased()
            print("Generated clientID is \(self.localSenderId)")
        }
        // Kinesis Video Client Configuration
        let configuration = AWSServiceConfiguration(region: self.awsRegionType, credentialsProvider: AWSMobileClient.default())
        AWSKinesisVideo.register(with: configuration!, forKey: awsKinesisVideoKey)

        retrieveChannelARN(channelName: channelNameValue)
        if self.channelARN == nil {
            createChannel(channelName: channelNameValue)
        }
        getSignedWSSUrl(channelARN: self.channelARN!, role: role, connectAs: connectAsUser, region: awsRegionValue)
        print("WSS URL :", wssURL?.absoluteString as Any)

        var RTCIceServersList = [RTCIceServer]()

        for iceServers in self.iceServerList! {
            RTCIceServersList.append(RTCIceServer.init(urlStrings: iceServers.uris!, username: iceServers.username, credential: iceServers.password))
        }

        RTCIceServersList.append(RTCIceServer.init(urlStrings: ["stun:stun.kinesisvideo." + self.regionName.text! + ".amazonaws.com:443"]))
        webRTCClient = WebRTCClient(iceServers: RTCIceServersList, isAudioOn: sendAudioEnabled)
        webRTCClient!.delegate = self

        print("Connecting to web socket from channel config")
        signalingClient = SignalingClient(serverUrl: wssURL!)
        signalingClient!.delegate = self
        signalingClient!.connect()

        let seconds = 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.updateConnectionLabel()
            self.vc = VideoViewController(webRTCClient: self.webRTCClient!, signalingClient: self.signalingClient!, localSenderClientID: self.localSenderId, isMaster: self.isMaster!)
            self.present(self.vc!, animated: true, completion: nil)
        }
    }

    func updateConnectionLabel() {
        if signalingConnected {
            connectedLabel!.text = "Connected"
            connectedLabel!.textColor = .green
        } else {
            connectedLabel!.text = "Not Connected"
            connectedLabel!.textColor = .red
        }
    }

    func createChannel(channelName: String) {
        let kvsClient = AWSKinesisVideo(forKey: awsKinesisVideoKey)
        let createSigalingChannelInput = AWSKinesisVideoCreateSignalingChannelInput.init()
        createSigalingChannelInput?.channelName = channelName
        kvsClient.createSignalingChannel(createSigalingChannelInput!).continueWith(block: { (task) -> Void in
            if let error = task.error {
                print("Error creating channel \(error)")
                return
            } else {
                self.channelARN = task.result?.channelARN
                print("Channel ARN : ", task.result?.channelARN)
            }
        }).waitUntilFinished()
        if (self.channelARN == nil) {
            let alertController = UIAlertController(title: "Unable to create channel",
                                                    message: "Please validate all the input fields",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)

            self.present(alertController, animated: true, completion: nil)
            return
        }
    }

    func retrieveChannelARN(channelName: String) {
        if !channelName.isEmpty {
            let describeInput = AWSKinesisVideoDescribeSignalingChannelInput()
            describeInput?.channelName = channelName
            let kvsClient = AWSKinesisVideo(forKey: awsKinesisVideoKey)
            kvsClient.describeSignalingChannel(describeInput!).continueWith(block: { (task) -> Void in
                if let error = task.error {
                    print("Error describing channel: \(error)")
                } else {
                    self.channelARN = task.result?.channelInfo?.channelARN
                    print("Channel ARN : ", task.result!.channelInfo!.channelARN ?? "Channel ARN empty.")
                }
            }).waitUntilFinished()
        } else {
            let alertController = UIAlertController(title: "Channel Name is Empty",
                                                    message: "Valid Channel Name is required.",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            return
        }
    }

    func getSingleMasterChannelEndpointRole() -> AWSKinesisVideoChannelRole {
        if isMaster! {
            return .master
        }
        return .viewer
    }
    
    func getSignedWSSUrl(channelARN: String, role: String, connectAs: String, region: String) {
        let singleMasterChannelEndpointConfiguration = AWSKinesisVideoSingleMasterChannelEndpointConfiguration()
        singleMasterChannelEndpointConfiguration?.protocols = videoProtocols
        singleMasterChannelEndpointConfiguration?.role = getSingleMasterChannelEndpointRole()
        
        var httpResourceEndpointItem = AWSKinesisVideoResourceEndpointListItem()
        var wssResourceEndpointItem = AWSKinesisVideoResourceEndpointListItem()
        let kvsClient = AWSKinesisVideo(forKey: awsKinesisVideoKey)

        let signalingEndpointInput = AWSKinesisVideoGetSignalingChannelEndpointInput()
        signalingEndpointInput?.channelARN = channelARN
        signalingEndpointInput?.singleMasterChannelEndpointConfiguration = singleMasterChannelEndpointConfiguration

        kvsClient.getSignalingChannelEndpoint(signalingEndpointInput!).continueWith(block: { (task) -> Void in
            if let error = task.error {
               print("Error to get channel endpoint: \(error)")
            } else {
                print("Resource Endpoint List : ", task.result!.resourceEndpointList!)
            }

            guard (task.result?.resourceEndpointList) != nil else {
                let alertController = UIAlertController(title: "Invalid Region Field",
                                                        message: "No endpoints found",
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(okAction)

                self.present(alertController, animated: true, completion: nil)
                return
            }
            for endpoint in task.result!.resourceEndpointList! {
                switch endpoint.protocols {
                case .https:
                    httpResourceEndpointItem = endpoint
                case .wss:
                    wssResourceEndpointItem = endpoint
                case .unknown:
                    print("Error: Unknown endpoint protocol ", endpoint.protocols, "for endpoint" + endpoint.description())
                }
            }
            AWSMobileClient.default().getAWSCredentials { credentials, _ in
                self.AWSCredentials = credentials
            }

            var httpURlString = (wssResourceEndpointItem?.resourceEndpoint!)!
                + "?X-Amz-ChannelARN=" + self.channelARN!
            if !self.isMaster! {
                httpURlString += "&X-Amz-ClientId=" + self.localSenderId
            }
            let httpRequestURL = URL(string: httpURlString)
            let wssRequestURL = URL(string: (wssResourceEndpointItem?.resourceEndpoint!)!)
            usleep(5)
            self.wssURL = KVSSigner
                .sign(signRequest: httpRequestURL!,
                      secretKey: (self.AWSCredentials?.secretKey)!,
                      accessKey: (self.AWSCredentials?.accessKey)!,
                      sessionToken: (self.AWSCredentials?.sessionKey)!,
                      wssRequest: wssRequestURL!,
                      region: region)

            // Get the List of Ice Server Config and store it in the self.iceServerList.

            let endpoint =
                AWSEndpoint(region: self.awsRegionType,
                            service: .KinesisVideo,
                            url: URL(string: httpResourceEndpointItem!.resourceEndpoint!))
            let configuration =
                AWSServiceConfiguration(region: self.awsRegionType,
                                        endpoint: endpoint,
                                        credentialsProvider: AWSMobileClient.default())
            AWSKinesisVideoSignaling.register(with: configuration!, forKey: awsKinesisVideoKey)
            let kvsSignalingClient = AWSKinesisVideoSignaling(forKey: awsKinesisVideoKey)

            let iceServerConfigRequest = AWSKinesisVideoSignalingGetIceServerConfigRequest.init()

            iceServerConfigRequest?.channelARN = channelARN
            iceServerConfigRequest?.clientId = self.localSenderId
            kvsSignalingClient.getIceServerConfig(iceServerConfigRequest!).continueWith(block: { (task) -> Void in
                if let error = task.error {
                    print("Error to get ice server config: \(error)")
                } else {
                    self.iceServerList = task.result!.iceServerList
                    print("ICE Server List : ", task.result!.iceServerList!)
                }
            }).waitUntilFinished()

        }).waitUntilFinished()
    }
}

extension ChannelConfigurationViewController: SignalClientDelegate {
    func signalClientDidConnect(_: SignalingClient) {
        signalingConnected = true
    }

    func signalClientDidDisconnect(_: SignalingClient) {
        signalingConnected = false
    }

    func setRemoteSenderClientId() {
        if self.remoteSenderClientId == nil {
            remoteSenderClientId = connectAsViewClientId
        }
    }
    
    func signalClient(_: SignalingClient, senderClientId: String, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        print("Received remote sdp from [\(senderClientId)]")
        if !senderClientId.isEmpty {
            remoteSenderClientId = senderClientId
        }
        setRemoteSenderClientId()
        webRTCClient!.set(remoteSdp: sdp) { _ in
            print("Setting remote sdp and sending answer.")
            self.vc!.sendAnswer(recipientClientID: self.remoteSenderClientId!)

        }
    }

    func signalClient(_: SignalingClient, senderClientId: String, didReceiveCandidate candidate: RTCIceCandidate) {
        print("Received remote candidate from [\(senderClientId)]")
        if !senderClientId.isEmpty {
            remoteSenderClientId = senderClientId
        }
        setRemoteSenderClientId()
        webRTCClient!.set(remoteCandidate: candidate)
    }
}

extension ChannelConfigurationViewController: WebRTCClientDelegate {
    func webRTCClient(_: WebRTCClient, didGenerate candidate: RTCIceCandidate) {
        print("Generated local candidate")
        setRemoteSenderClientId()
        signalingClient?.sendIceCandidate(rtcIceCandidate: candidate, master: isMaster!,
                                          recipientClientId: remoteSenderClientId!,
                                          senderClientId: self.localSenderId)
    }

    func webRTCClient(_: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        switch state {
        case .connected, .completed:
            print("WebRTC connected/completed state")
        case .disconnected:
            print("WebRTC disconnected state")
        case .new:
            print("WebRTC new state")
        case .checking:
            print("WebRTC checking state")
        case .failed:
            print("WebRTC failed state")
        case .closed:
            print("WebRTC closed state")
        case .count:
            print("WebRTC count state")
        @unknown default:
            print("WebRTC unknown state")
        }
    }

    func webRTCClient(_: WebRTCClient, didReceiveData _: Data) {
        print("Received local data")
    }
}

extension String {
    func trim() -> String {
        return trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
}
