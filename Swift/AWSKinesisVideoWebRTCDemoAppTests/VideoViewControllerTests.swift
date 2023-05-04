import XCTest
import UIKit
import WebRTC
@testable import AWSKinesisVideoWebRTCDemoApp

class VideoViewControllerTests: XCTestCase{
    
    var videoViewController: VideoViewController?
    var webRTCClient: WebRTCClient?
    var signalingClient: SignalingClient?
    var channelVC: ChannelConfigurationViewController?
    
    override func setUp() {
        
        let storyboard = UIStoryboard(name: "Main",bundle: Bundle.main)
        channelVC = storyboard.instantiateViewController(identifier: "channelvc")
        var RTCIceServersList = [RTCIceServer]()
        signalingClient = SignalingClient(serverUrl: URL.init(string: "wss://aws.amazon.com/")!)
        signalingClient!.delegate = channelVC
        signalingClient!.connect()
        
        RTCIceServersList.append(RTCIceServer.init(urlStrings: ["stun:stun.kinesisvideo." + "us-west-2" + ".amazonaws.com:443"]))
        webRTCClient = WebRTCClient(iceServers: RTCIceServersList, isAudioOn: true)
        webRTCClient!.delegate = channelVC
        videoViewController = VideoViewController(webRTCClient: self.webRTCClient!, signalingClient: self.signalingClient!, localSenderClientID: "randomClientID", isMaster: true, mediaServerEndPoint: nil)
    }
    
    override func tearDown() {
    }
    
    func testVideoViewControllerComponents() {
        XCTAssertNotNil(videoViewController?.viewDidLoad())
        XCTAssertNotNil(videoViewController?.localVideoView)
        XCTAssertNoThrow(videoViewController?.backDidTap(videoViewController as Any))
    }
}
